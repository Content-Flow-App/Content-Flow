## Design decisions

1. **Post-auth routing** — override `after_sign_in_path_for` / `after_sign_up_path_for` in `ApplicationController`. Single branch: `creator.present? ? dashboard_path : new_creator_path`. No global `before_action` wizard lock.
2. **Onboarding state** — derived from data (no flag). `User#onboarding_complete?`, `User#next_onboarding_step` (`:creator|:idea|:script|:post|:done`).
3. **Dashboard** — new `DashboardController#show`; keep `pages#home` public (redirect to dashboard when signed in).
4. **Polymorphic chat** — add `chattable_type`/`chattable_id` to `chats`; `Chat belongs_to :chattable, polymorphic: true, optional: true`; content models `has_many :chats, as: :chattable`. **Owners: `User`, `Idea`, `Script`, `LinkedinPost` (all `has_many`). `Creator` owns no chats** — since `User has_one :creator` (1:1), top-level chats live on the `User` to avoid a redundant User/Creator overlap; `LlmContext` reaches brand context via `user.creator`. (Supersedes #47's literal `has_one` on Creator.)
5. **Cascading LLM context** — `LlmContext.for(chattable)` walks the ancestry chain (`LinkedinPost → Script → Idea → User → Creator`) and builds a layered system prompt; applied via `chat.with_instructions(...)` at chat creation. Verified ruby_llm v1.15.0 `with_instructions` persists a `role: :system` message.
6. **Structured generation** — `RubyLLM::Schema` subclasses (`IdeaSchema/ScriptSchema/LinkedinPostSchema`) on the generation path via `with_schema`.
7. **Guided but skippable** — only the creator-profile branch is enforced; everything else is CTAs/redirects.
8. **Authorization** — scripts/posts have no `user_id`; ownership runs through `idea.user`.

## End-to-end verification

1. **First-run:** sign up → `new_creator_path` → submit creator → `new_idea_path` → create idea → "Write a script" → create script → "Turn into LinkedIn post" → create post → "Go to dashboard" → dashboard shows the chain + hidden/complete banner.
2. **Returning:** sign out/in → `dashboard_path` → "New idea" → repeat from dashboard, never gated.
3. **Guided-but-skippable:** creator-but-no-ideas user can still visit `/models`, `/chats`; banner shows next step = idea.
4. **Cascading chat:** idea chat → system message has creator topic/goal/audience; script chat → +parent idea; post chat → +idea+script. Generation path → `with_schema` JSON maps onto records.
5. **Authorization:** user B hitting user A's `script_path`/`linkedin_post_path` → blocked.
6. Run `bin/rails test` after each EPIC.

### Generation engine

`chats/show` renders a conditional `button_to` → nested **singular** `resource :generation` →
`GenerationsController#create` (synchronous):

1. Re-resolve & **authorize** the chattable through user-scoped relations (don't trust
   `chat.chattable`); `find` on a scoped relation → 404 for non-owners.
2. Build a transcript from the chat's visible user/assistant messages.
3. Extract on a **transient** chat (keeps the visible transcript clean):
   `RubyLLM.chat(model:).with_instructions(…).with_schema(plan.schema).ask(transcript)`.
   On success `message.content` is a parsed **Hash** (gem `JSON.parse`s it).
4. **Fallback** if the endpoint rejects `response_format: json_schema`: retry without a schema,
   instruct "respond with only a JSON object with keys …", strip ```` ```json ```` fences,
   `JSON.parse` with rescue.
5. Validate keys present → `symbolize_keys.slice(*permitted)` → non-bang `create`/`update` with an
   error branch → redirect to the record (`linkedin_post.present?` guard for the singular post).

`GenerationPlan` (a PORO in `app/services/`) holds the table above as the single source of truth;
`current_user_linkedin_posts` is added to `UserScopedResource`.

> **Endpoint risk (GATE RESOLVED — F-3, 2026-06-05):** structured output via `with_schema`
> **works reliably** against the configured GitHub-Models/Azure `gpt-4o-mini` endpoint. The day-1
> spike ran `with_schema(IdeaSchema/ScriptSchema/LinkedinPostSchema).ask(...)` live (incl. the
> transient `with_instructions` + `with_schema` pattern F-2 uses) and got a parsed **Hash** with
> all schema keys on **6/6** calls. **Decision: F-2 builds on `with_schema` as the PRIMARY path.**
> The prompt-JSON fallback is built and verified live anyway as a safety net (model/endpoint
> regression). Both paths are wrapped in `StructuredExtraction` (`app/services/`), which returns a
> Hash from `with_schema` first and falls back to prompt-JSON + fence-strip + `JSON.parse` only if
> the gem returns a raw String. Verified in `ruby_llm-1.15.0`: `chat.with_schema` delegates to the
> in-memory chat (`chat_methods.rb:154`) and the gem silently falls back to the raw String on a
> parse failure (`chat.rb:172`).

### Fold-in cleanup

Remove `readonly: true` from `ideas/_form.html.erb` (broke editing); delete
`IdeasController#generate_idea`, the `post :generate_idea` route, and `_generate_idea_form.html.erb`
(+ its render in `ideas/new`). `resources :generated_ideas` is left alone (separate AI-feed track).

### chattable_type → schema / scope / persistence (single source of truth)

| chattable_type | schema | authorize via | persist | redirect |
|---|---|---|---|---|
| `Idea` | `IdeaSchema` | `current_user.ideas.find` | `record.update` | `idea_path` |
| `Script` | `ScriptSchema` | `current_user_scripts.find` | `record.update` | `script_path` |
| `LinkedinPost` | `LinkedinPostSchema` | `current_user_linkedin_posts.find` | `record.update` | `script_linkedin_post_path(record.script)` |
| `User` / standalone | — | — | — | no apply button (plain chat, unchanged) |

Permitted keys = each schema's properties — Idea `[:title,:description,:topic]`; Script
`[:title,:description,:style,:length]`; LinkedinPost `[:title,:hook,:body]`. `StructuredContent`
already slices to the schema's property keys.

### Mechanics

1. **Entry (original F2).** "refine with ai" `cf-action` link →
   `new_chat_path(chat: {chattable_type: "Idea", chattable_id: @idea.id})`. `chats/_form` renders
   hidden `chat[chattable_type]`/`chat[chattable_id]` fields; `ChatsController#new` seeds
   `@chat = Chat.new(chattable_type:, chattable_id:)` from allowlisted params (`CHATTABLE_TYPES`).
   The existing `#create` already reads those params, attaches the chattable, applies
   `LlmContext.for(...)`, and streams — **no change to `#create`**.
2. **Apply.** `chats/show` renders a conditional `button_to` "apply changes to this …" (gated on
   `chattable` being Idea/Script/LinkedinPost **and** visible messages existing) → nested singular
   `resource :refinement` → `RefinementsController#create` (synchronous):
   - **Authorize** by re-resolving the chattable through user-scoped relations (`.find` → 404 for
     non-owners). **Never trust `chat.chattable`.**
   - **Guard** empty transcript (only a system message) → redirect back with an alert.
   - Build a transcript from visible `user`/`assistant` messages (`content`, skip blanks/system).
   - **Transient extraction** (throwaway, not persisted to the chat):
     `RubyLLM.chat(model: model_string).with_instructions(refine_instructions(record)).with_schema(schema_for(record)).ask(transcript)`.
   - `StructuredContent.assign(record, schema, payload)` → non-bang `record.save` with an error
     branch → redirect to the record's show page with a notice.

### Edge-case fixes (must be honored in implementation)

- **Model resolution (bug):** `@chat.model_id` returns the *string* id only when a `Model` row is
  attached; with the default model it is `nil`. Use
  `model_string = @chat.model_id.presence || RubyLLM.config.default_model` (`"gpt-4o-mini"`).
- **No-change bias (bug):** `LlmContext` embeds the record's **current** content, so a bare schema
  ask tends to echo it back. The extraction instructions must say: *"The conversation is a
  refinement discussion about THIS [idea/script/post]. Produce the improved version reflecting the
  conversation. Output every field; for any field the conversation did not discuss, return its
  current value unchanged."* — this both overcomes the bias and implements the chosen
  **overwrite-all-keep-undiscussed** behavior.
- **`with_schema` reliability (F-3 verified 2026-06-05):** confirmed reliable on the
  GitHub-Models/Azure `gpt-4o-mini` endpoint (6/6 live calls returned a parsed Hash), so
  `with_schema` is the primary path. The gem can still silently return a raw String on parse
  failure, so **reuse `StructuredExtraction` (`app/services/`) from #84** — it tries `with_schema`
  first and falls back to schema-less prompt-JSON (instruct "respond with only a JSON object with
  keys …", strip ```` ```json ```` fences, `JSON.parse` with rescue), raising `ExtractionFailed`
  if both fail. `StructuredContent` then maps the Hash onto the record.
- **Validation failure:** non-bang `save`; on `false` re-render `chats/show` with
  `status: :unprocessable_entity` and `record.errors.full_messages`.
- **Singular post redirect:** `script_linkedin_post_path(record.script)` (no id).

### Files the implementation will touch

- New: `app/controllers/refinements_controller.rb`
- `config/routes.rb` — `resource :refinement, only: [:create]` nested under `resources :chats`
- `app/controllers/concerns/user_scoped_resource.rb` — add `current_user_linkedin_posts`
  (`LinkedinPost.joins(script: :idea).where(ideas: { user_id: current_user.id })`)
- `app/controllers/chats_controller.rb` — `#new` seeds `@chat` from allowlisted chattable params
- `app/views/chats/_form.html.erb` — hidden `chattable_type`/`chattable_id` fields
- `app/views/chats/show.html.erb` — conditional apply `button_to` + DESIGN.md restyle
- `app/views/ideas/show.html.erb`, `scripts/show.html.erb`, `linkedin_posts/show.html.erb` —
  "refine with ai" `cf-action` CTA
- **Unchanged / reused:** `app/services/structured_content.rb`, `app/schemas/*.rb`,
  `app/services/llm_context.rb`, `app/jobs/chat_response_job.rb`, all manual CRUD forms.

  