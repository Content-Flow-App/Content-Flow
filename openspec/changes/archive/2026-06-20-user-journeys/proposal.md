# User Journeys — Plan & Issue Set

> Source of truth for wiring the two core user journeys end-to-end. Written before the
> GitHub issues are created so the plan survives independently of the board. Keep this
> doc and the created issues in sync.

## The two journeys

1. **First-run:** Sign Up → Creator Profile → Create First Idea → Create First Script → Create First LinkedIn Post → Dashboard.
2. **Returning:** Sign In → Dashboard → New Idea → New Script → New LinkedIn Post.

## Current state (verified)

- **Auth (Devise):** sign up + sign in work. `ApplicationController` gates everything with `authenticate_user!`; `pages#home` is the only public action.
- **Models + tables all exist:** `Creator(name,topic,goal,audience,user_id)`, `Idea(title,description,topic,user_id)`, `Script(title,description,style,length,system_prompt,idea_id)`, `LinkedinPost(title,hook,body,script_id)`, plus `GeneratedIdea` and the ruby_llm `Chat/Message/Model`.
- **Creator form** (`new`/`edit`) built; `show` empty; `creator_params` bug (`require(:creators)` → should be `:creator`).
- **Empty shells:** `IdeasController`, `ScriptsController`, `LinkedinPostsController`, `GeneratedIdeasController` — no actions; views are empty stubs.
- **Missing entirely:** dashboard, navigation, post-signup redirect logic, links between steps.
- **Chat has no owner:** `chats` table has only `model_id`.

## Gap analysis

| Journey step | Model | Table | Controller | Views | Gap |
|---|---|---|---|---|---|
| Sign up / in | User (Devise) | ✓ | built-in | ✓ | none — add post-auth redirect |
| Creator profile | ✓ | ✓ | partial | new/edit only | show + param fix + redirect |
| Idea | ✓ | ✓ | empty | empty | full CRUD + views |
| Script | ✓ | ✓ | empty | empty | full CRUD (nested/shallow) |
| LinkedIn post | ✓ | ✓ | empty | empty | full CRUD (singular nested) |
| Dashboard | — | — | none | none | new controller + view |
| Navigation | — | — | — | none | nav partial |
| Chat ownership | Chat | partial | ✓ | ✓ | polymorphic `chattable` |
| Creator-aware LLM | — | — | — | — | system-instruction context |

## Addendum — Chat-driven Generation (F2/F4 reframe)

> Written 2026-06-04. Reframes the original **F2** (chat links on show pages) and **F4** (schema
> wiring) into a single **generate-via-chat** flow on each `new` action. F1 (`chattable`) and F3
> (`LlmContext`) are done and unchanged; F4's schema classes are built and get wired here.
> **Scope decision (5 days / 4 devs, shared with other features):** ship **generate** for
> idea/script/post now; **refine** (chat-edit an existing record) is a deferred follow-up that
> reuses the same engine.

### The flow

Each `new` action **redirects** to the existing chat composer (`/chats/new`), carrying a
`purpose` + the chattable context. The user converses freely (existing streaming path, with
`LlmContext` instructions applied as today). The chat show page then offers a single
**"save as idea / script / post"** button that runs a **one-shot structured extraction** and
creates the record.

```
ideas#new            → /chats/new?purpose=generate_idea&chattable_type=User&chattable_id=…
scripts#new (@idea)  → /chats/new?purpose=generate_script&chattable_type=Idea&chattable_id=…
posts#new   (@script)→ /chats/new?purpose=generate_linkedin_post&chattable_type=Script&chattable_id=…
```

### `purpose` — the discriminator

A chat carries a `purpose` because chattable type alone is ambiguous (a chat on an `Idea` could
mean "refine this idea" or "generate a child script"). MVP values: `generate_idea`,
`generate_script`, `generate_linkedin_post` (nil = a plain free-form chat, behavior unchanged).
The deferred refine work adds `refine_idea / refine_script / refine_linkedin_post`.

| purpose | schema | chattable (context) | resolve owner via | persist | redirect |
|---|---|---|---|---|---|
| `generate_idea` | `IdeaSchema` | current_user | self | `current_user.ideas.create` | `idea_path` |
| `generate_script` | `ScriptSchema` | Idea | `current_user.ideas.find` | `idea.scripts.create` | `script_path` |
| `generate_linkedin_post` | `LinkedinPostSchema` | Script | `current_user_scripts.find` | post exists? `update` : `build_linkedin_post.save` | `script_linkedin_post_path` |

Permitted keys — Idea `[:title,:description,:topic]`; Script `[:title,:description,:style,:length]`;
LinkedinPost `[:title,:hook,:body]`. Always `symbolize_keys.slice(*permitted)` before writing.

## Addendum — Refine with AI (additional journey)

> Written 2026-06-05. An **alternative/additional** AI journey that sits **alongside** the
> Chat-driven Generation reframe above — it does **not** replace or modify it. Where the generate
> reframe turns each `new` action into a chat *redirect* (creating brand-new records), this track
> keeps the **manual CRUD forms we already built (C1/D1/E1) 100% intact** and adds one thing: the
> ability to open an AI chat **from an existing record's show page** and **apply** the AI's
> structured suggestion back onto *that same record*. It is the original **F2** ("wire chat entry
> points into show pages") plus the realization of the deferred **#89**. The generate addendum and
> its issues (#82–#88) are unchanged.

### Why this is more in line with what we have already built

| Concern | Generate reframe (#82) | Refine with AI (this track) |
|---|---|---|
| Manual CRUD forms | bypassed (`new` → redirect) | **kept 100% intact** |
| New DB column | `purpose:string` + `enum` migration | **none** — `chattable_type` selects the schema |
| Persistence | create-vs-update branch, owner resolution, "post exists?" guard | **always `update` the chattable** (it *is* the target) |
| New controller | `GenerationsController` + `GenerationPlan` PORO | `RefinementsController` + a tiny type→schema map |
| Reuse | schemas only | `LlmContext`, schemas, **`StructuredContent` (already built)**, `ChatResponseJob`, chat views |

Everything the refine engine needs is already done: F1 (`chattable`), F3 (`LlmContext` — which
**already embeds the record's current content** + ancestry + creator), F4 schemas, and the
`StructuredContent.assign(record, Schema, payload)` service.

### The flow

A **"refine with ai"** CTA on each show page opens a chat **attached to that record** (`chattable`).
The user converses freely — the existing `ChatsController#create` flow applies `LlmContext`
instructions and streams via `ChatResponseJob`, unchanged. `chats/show` then offers an **"apply
changes to this idea / script / post"** button that runs a **one-shot structured extraction on a
transient chat** (keeping the visible transcript clean) and **updates the existing record**, then
redirects back to its show page.

```
ideas#show         → "refine with ai" → /chats/new?chat[chattable_type]=Idea&chat[chattable_id]=…
scripts#show       → "refine with ai" → /chats/new?chat[chattable_type]=Script&chat[chattable_id]=…
linkedin_posts#show→ "refine with ai" → /chats/new?chat[chattable_type]=LinkedinPost&chat[chattable_id]=…
```

### No `purpose` discriminator

Unlike the generate reframe, this track adds **no `purpose` column**. Refine is the only AI journey
here, and `chattable_type` *alone* unambiguously selects the schema; every action is an **update of
the chattable itself** (no create, no "post exists?" branch, no owner gymnastics — the chattable
*is* the target). A `User`/standalone chat simply shows no apply button (plain chat, unchanged).

