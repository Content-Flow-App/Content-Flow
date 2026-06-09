# LLM Blueprint — Greenfield Rails + RubyLLM

> A from-scratch reference for wiring an AI-native Rails app where users (with profiles) drive a
> flow that **generates and refines** domain objects through a polymorphic chat. This is the
> *ideal-state* blueprint — no migration baggage — and a companion to `LLM_ARCHITECTURE.md`, which
> describes migrating an existing app toward the same ideas.
>
> Grounded in `ruby_llm` features verified against <https://rubyllm.com/> (chat, schemas, tools,
> agents, Rails integration) in June 2026. Code blocks are **illustrative blueprints**, not literal
> drop-in code.

---

## 1. The shape in one breath

A **polymorphic `Chat`** carries a **`purpose`** of the form `"<verb>_<object>"`. That single key
resolves to a **`RubyLLM::Agent`** (developer directives + schema + tools) and a **plan** (owner /
persist / redirect). Domain models expose **facts** about themselves through a `Contextualizable`
concern; the agent's **ERB prompt template** decides the *order* in which facts, creator directives,
and developer directives are stitched together. **Generate and refine are the same machine** — they
differ only in whether the chat's `chattable` is the object's **parent** (generate) or the **object
itself** (refine).

The organizing idea (see `LLM_ARCHITECTURE.md §2`) is the grid: every prompt contribution is
**facts vs. directives** × **developer-owned (code) vs. creator-owned (data)**. The blueprint gives
each cell its own owner and its own RubyLLM delivery channel.

---

## 2. Skeleton — generators, config, directories

```bash
bin/rails generate ruby_llm:install          # Chat / Message / ToolCall / Model tables + acts_as + ActiveStorage
bin/rails db:migrate
bin/rails ruby_llm:load_models               # populate the Model registry from models.json
bin/rails generate ruby_llm:chat_ui          # controllers/views/jobs/routes + Turbo streaming starter

bin/rails generate ruby_llm:agent  Ideas::Generate
bin/rails generate ruby_llm:tool   RecentObjects
bin/rails generate ruby_llm:schema Idea
```

```ruby
# config/initializers/ruby_llm.rb
RubyLLM.configure do |c|
  c.openai_api_key    = Rails.application.credentials.openai_api_key
  c.anthropic_api_key = Rails.application.credentials.anthropic_api_key
  c.default_model     = "claude-sonnet-4-6"
  c.use_new_acts_as   = true                 # modern API; default in new apps
  c.logger            = Rails.logger
  c.request_timeout   = Rails.env.production? ? 120 : 30
end
```

```
app/
  models/
    user.rb            # has_one :profile; has_many :chats, as: :chattable
    profile.rb         # persona/brand facts + house_style (a creator directive)
    chat.rb            # acts_as_chat + belongs_to :chattable, polymorphic + purpose enum
    message.rb         # acts_as_message
    tool_call.rb       # acts_as_tool_call
    model.rb           # acts_as_model
    concerns/
      contextualizable.rb
    <domain objects>   # each includes Contextualizable
  agents/
    application_agent.rb
    ideas/generate_agent.rb
    ideas/refine_agent.rb
  prompts/
    ideas/generate_agent/instructions.txt.erb   # developer directive prose (ERB; sees inputs)
    ideas/refine_agent/instructions.txt.erb
  schemas/
    idea_schema.rb                              # structured-output contract
  tools/
    application_tool.rb
    recent_objects_tool.rb                      # pull-path facts, user-scoped
  services/
    completion.rb        # resolve purpose -> agent + plan; run; persist; redirect
    completion_plan.rb   # registry: purpose -> {agent, owner, persist, redirect}
    prompt_context.rb    # composer: facts + creator directives as labeled segments
  jobs/
    chat_stream_job.rb
```

`ruby_llm:install` provides the `Chat / Message / ToolCall / Model` tables and their `acts_as_*`
declarations. Tool calls auto-persist to the `ToolCall` table; tokens/costs are normalized and
persisted per message.

---

## 3. Domain layer

```ruby
# Universal conversation — never references a specific object type.
class Chat < ApplicationRecord
  acts_as_chat
  belongs_to :chattable, polymorphic: true, optional: true   # context anchor: parent OR the object
  enum :purpose,
       %w[generate_idea refine_idea generate_post refine_post].index_with(&:itself),
       validate: { allow_nil: true }
end

class User < ApplicationRecord
  has_one  :profile
  has_many :chats, as: :chattable
end

class Profile < ApplicationRecord   # name, audience, goal, house_style (creator directive)
  belongs_to :user
end
```

### `Contextualizable` — the model-owned **facts** path

Each object that can anchor a chat declares *what facts describe me* and *who is my context parent*.
A walk up the chain assembles ancestry facts. This is the generalized form of a per-model
`#system_prompt`, with facts kept strictly separate from directives.

```ruby
module Contextualizable
  extend ActiveSupport::Concern

  class_methods do
    def context_parent(name) = @context_parent = name
    def context_parent_name  = @context_parent
  end

  # Facts about THIS record — a labeled segment, never instructions.
  def context_facts = raise NotImplementedError

  # Ancestry first: parent → ... → profile, then self.
  def context_chain
    parent = self.class.context_parent_name && public_send(self.class.context_parent_name)
    (parent&.context_chain || []) + [context_facts]
  end
end

class Idea < ApplicationRecord
  include Contextualizable
  context_parent :user                       # user.profile facts sit above the idea
  has_many :chats, as: :chattable
  def context_facts = Segment.facts("IDEA", title:, summary:)
end
```

---

## 4. The grid → where each thing lives

| Grid cell | Home | Delivery channel |
|---|---|---|
| Developer directives | `app/prompts/<agent>/instructions.txt.erb` + agent class | Agent `instructions` (system message) |
| Output structure | `app/schemas/<object>_schema.rb` | `schema` → `response_format` |
| Creator facts (small, always relevant) | model `#context_facts` via `Contextualizable` | *pushed* into the prompt |
| Creator facts (large / optional) | `app/tools/*_tool.rb` (user-scoped) | **tools** — model *pulls* on demand |
| Creator directives | `Profile#house_style`, `Object#custom_instructions` columns | own labeled segment |

---

## 5. Agents + ordering via the prompt template

The agent binds developer directives, schema, model, and tools. RubyLLM auto-loads the directive
prose from `app/prompts/<agent>/instructions.txt.erb` — and **that template is the ordering knob**:
it interpolates each separated source wherever the author chooses.

```ruby
# app/agents/application_agent.rb
class ApplicationAgent < RubyLLM::Agent
  chat_model Chat                  # Rails mode: persists/streams through acts_as_chat
  model "claude-sonnet-4-6"
  inputs :chattable                # runtime anchor; ERB + tools read it
end

# app/agents/ideas/generate_agent.rb
module Ideas
  class GenerateAgent < ApplicationAgent
    schema IdeaSchema
    tools { [ RecentObjectsTool.new(user: chattable.user) ] }   # pull facts, user-scoped
  end
end
```

```erb
<%# app/prompts/ideas/generate_agent/instructions.txt.erb — ORDER lives here %>
You are <%= app_name %>'s assistant. Create a new idea for this creator.

<%= PromptContext.facts(chattable) %>                <%# creator facts, ancestry-ordered %>

<%= PromptContext.creator_directives(chattable) %>   <%# house_style / custom_instructions, separate %>

HOW TO WRITE A GOOD IDEA
- ... developer directives specific to *generate* ...
```

`PromptContext` is the thin composer: it reads `chattable.context_chain` for facts and the
profile/object directive columns, renders each as a labeled block, and returns strings the template
places.

- **Separation** = distinct helpers per cell (facts vs. creator directives vs. developer prose).
- **Flexible ordering** = the template decides; precedence is explicit (move a line up/down).
- **Testable** = assert segment set + order with no LLM call.

---

## 6. Schemas — the structural directive

```ruby
# app/schemas/idea_schema.rb
class IdeaSchema < RubyLLM::Schema
  string :title,   description: "Short, punchy working title."
  string :summary, description: "One or two sentences capturing the angle."
end
```

Attached via the agent's `schema` macro (or `with_schema` on a transient chat). The same schema
serves both generate and refine of that object — structure is independent of verb.

---

## 7. Generate / refine symmetry (the heart of it)

One registry maps `purpose` → behavior. Generate and refine reuse the **same schema**; they differ
only in the **agent** (directives) and the **anchor**.

```ruby
# app/services/completion_plan.rb
CompletionPlan = Data.define(:agent, :resolve_owner, :persist, :redirect)

REGISTRY = {
  "generate_idea" => CompletionPlan.new(
    agent:         Ideas::GenerateAgent,
    resolve_owner: ->(user, _id) { user },                       # parent = the user
    persist:       ->(owner, attrs) { owner.ideas.build(attrs) },
    redirect:      ->(rec) { idea_path(rec) }),

  "refine_idea" => CompletionPlan.new(
    agent:         Ideas::RefineAgent,
    resolve_owner: ->(user, id) { user.ideas.find(id) },          # anchor = the idea itself
    persist:       ->(idea, attrs) { idea.assign_attributes(attrs); idea },
    redirect:      ->(rec) { idea_path(rec) }),
}.freeze
```

The decisive behavior is **automatic** and falls out of `Contextualizable`:

- **Generate** → `chattable` is the *parent* → the chain has profile + parent facts but **no idea
  facts** (it doesn't exist yet). The agent's directives say "create a new one."
- **Refine** → `chattable` *is the idea* → the chain now **includes the idea's current values**, so
  the model sees exactly what it's editing. The agent's directives say "improve this, preserve intent."

```ruby
# app/services/completion.rb — the structured SAVE step (separate from the visible transcript)
class Completion
  def self.run(chat:, transcript:, user:)
    plan   = CompletionPlan::REGISTRY.fetch(chat.purpose)
    owner  = user.instance_exec(chat.chattable_id, &plan.resolve_owner)   # user-scoped == authz
    attrs  = plan.agent.with(chattable: chat.chattable)                   # inputs → prompt + tools + schema
                       .ask(transcript).content                          # => parsed Hash (schema path)
    record = plan.persist.call(owner, attrs.slice(*plan.agent.schema.properties.keys))
    record.save! && record
  end
end
```

Adding an object is then a fixed recipe: **one schema + two agents + two prompt files + two registry
rows.**

---

## 8. Two LLM moments, two delivery modes

1. **The conversation** (free-form back-and-forth) → persisted `Chat`, **streamed** via
   `ChatStreamJob` + Turbo (the `chat_ui` generator supplies controllers/views/jobs). Tool calls
   auto-persist to the `ToolCall` table.
2. **The save** (structured extraction) → a one-shot agent `ask` with a `schema`, run on a transient
   chat so it never pollutes the visible transcript. Returns a parsed Hash. Keep a prompt-JSON
   fence-strip **fallback** for endpoints that ignore `response_format`.

---

## 9. Cross-cutting concerns to wire from day one

- **Authorization** — in two places, both via the signed-in user's associations: `resolve_owner`
  scopes the anchor (`user.ideas.find` → 404 on a foreign id), and **tools take `user:` in their
  constructor** so a tool can only read that creator's data.
- **Per-tenant keys / model choice** — `RubyLLM.context { |c| c.openai_api_key = tenant.key }` passed
  as `Chat.create!(context:)` for bring-your-own-key or per-user model selection. (Context isn't
  persisted — reset on reload.)
- **Cost & tokens** — `message.tokens.input/output`, `chat.cost.total` are persisted and normalized
  across providers; surface for quotas/limits.
- **Attachments** — `chat.ask("...", with: params[:file])` via ActiveStorage when objects are
  generated from uploads.
- **Instrumentation** — RubyLLM emits `ActiveSupport::Notifications` events automatically; subscribe
  for latency/cost dashboards.

---

## 10. Testing strategy

Because facts and directives are separated and ordering is template-driven, most of the system is
deterministically testable without the network:

- **`PromptContext`** — segment set + order per purpose (mirror the `LlmContext` heading/order tests).
- **`CompletionPlan`** — each `purpose` resolves to the right agent/owner; unknown purpose handled.
- **Schema round-trip** — agent with `schema` returns a parsed Hash on the configured endpoint;
  the prompt-JSON fallback covers the ignore-`response_format` case.
- **Tools** — called when relevant, ignored otherwise, and strictly user-scoped.
- **Live-LLM smoke** — one happy-path generate + refine per object; keep these few.

---

## 11. Build order

1. `ruby_llm:install` + `chat_ui` → a working streamed chat.
2. `Chat` gains polymorphic `chattable` + `purpose`.
3. `Contextualizable` + `PromptContext` → the facts path, tested.
4. One object's `generate` + `refine` agents, schema, prompts, and `CompletionPlan` rows → prove the
   symmetry end-to-end.
5. Repeat per object (the fixed recipe in §7).
6. Add the first **tool** only when a fact is genuinely large/optional (recent objects, web/RAG).

The payoff over a retrofit: facts are never fused into directives, ordering is a template concern
from the start, and every new object or verb is a mechanical, low-risk addition.
