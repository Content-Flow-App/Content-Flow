## Context

`config/initializers/ruby_llm.rb` configures RubyLLM (`use_new_acts_as = true`), which backs `RubyLLM.models` with an ActiveRecord-mirrored registry (`Model` / `acts_as_model`, `Chat` / `acts_as_chat`) instead of the gem's bundled static JSON. `available_chat_models` (`app/controllers/application_controller.rb`) currently returns every chat-capable model across every provider RubyLLM knows about — roughly 1350 rows spanning openai, anthropic, gemini, deepseek, mistral, perplexity, xai, azure, bedrock, vertexai, openrouter, ollama, and gpustack. Only `openai` (routed through GitHub Models, not real OpenAI) has ever had a working key; `anthropic` was a `nil`-valued stub. `ANTHROPIC_API_KEY` is now set on Heroku and confirmed live (`HTTP 200` against `api.anthropic.com/v1/models`, and `claude-sonnet-5` is confirmed to be the exact id Anthropic reports).

The model `<select>` needed for a switcher already exists in `app/views/chats/_form.html.erb`, wired to `@chat_models` / `@selected_model`, but is wrapped in `class="mb-6 hidden"` and was never scoped to working providers — presumably hidden for exactly the reason above (picking an unconfigured provider crashes with `RubyLLM::ConfigurationError`).

A prior change (see `config/initializers/ruby_llm.rb`) added a `RubyLLM::Providers::OpenAI` prepend that rewrites the outgoing `model` field to carry a publisher prefix (`openai/gpt-4o-mini`) only when `openai_api_base` points at `models.github.ai` — a workaround for GitHub Models' new endpoint contract. That patch is provider- and endpoint-scoped and does not interact with the Anthropic provider or with `default_model` resolution; it is unaffected by this change.

## Goals / Non-Goals

**Goals:**
- Make Claude Sonnet 5 (`anthropic` provider) the default model for new chats.
- Keep `gpt-4o-mini` (`openai` provider, via GitHub Models) fully available as a non-default option.
- Give users a working model switcher when starting a new chat, scoped strictly to providers that are actually configured.
- Ensure the registry has real metadata for `claude-sonnet-5` (pricing, context window, capabilities) rather than a placeholder stub, so `default_model_display_name` and the switcher's labels are accurate.

**Non-Goals:**
- Switching the model on an already-started chat (`chats/show.html.erb`). The model is fixed at `Chat.create!` time, as it is today; `RubyLLM::ActiveRecord::ChatMethods#with_model` exists in the gem but isn't wired to any controller action here.
- Surfacing `chat.cost` or any cost/pricing UI. Deferred explicitly by the user.
- Un-hiding or exposing any provider other than `openai` and `anthropic` (gemini, deepseek, mistral, perplexity, xai, azure, bedrock, vertexai, openrouter, ollama, gpustack stay excluded from the picker; their `Model` rows are untouched).
- Changing GitHub Models' payload-prefixing patch or endpoint.

## Decisions

### 1. Scope `available_chat_models` by provider allowlist, not by "is configured"

`application_controller.rb#available_chat_models` becomes:

```ruby
CHAT_PROVIDERS = %w[openai anthropic].freeze

def available_chat_models
  RubyLLM.models.chat_models.all
         .select { |model| CHAT_PROVIDERS.include?(model.provider.to_s) }
         .sort_by { |model| [ model.provider.to_s, model.name.to_s ] }
end
```

An explicit allowlist (rather than checking each provider's `configured?`) is simpler, matches how the initializer already documents "Working" vs "Dummy" providers in comments, and fails safe: if a future dummy key is accidentally set (e.g. someone exports `GEMINI_API_KEY` locally for an unrelated experiment), the switcher still won't surface it. The tradeoff is a second place (here, plus the initializer) that has to be updated if a third provider is ever turned on — acceptable given how rarely that happens.

**Alternative considered**: iterate providers and call `provider_class.configured?(config)`. Rejected — more moving parts for the same two-provider list, and `configured?` semantics vary per provider (e.g. Azure accepts either an API key or an auth token), which is more surface area than this change needs.

### 2. Un-hide the existing `<select>` rather than building a new component

The select, its `options_for_select` wiring against `@chat_models`/`@selected_model`, and the controller plumbing (`chats_controller.rb#new` sets `@selected_model = params[:model]`; `#create` passes `model: params.dig(:chat, :model).presence` into `Chat.create!`) already exist and already work — they were just never scoped or shown. This change removes `hidden` from the wrapping `div`, gives it a real `cf-label`, and confirms it renders per `DESIGN.md` (`.cf-select`-equivalent styling, no shadows, matches the rest of the composer). No new controller logic is needed for the "pick a model" half of this change.

### 3. `default_model` becomes `claude-sonnet-5`, unconditionally (no env-based toggle)

`RubyLLM.config.default_model = "claude-sonnet-5"` in the initializer, replacing `"gpt-4o-mini"`. This is a direct, explicit decision from the user — not something to hide behind a feature flag or environment check. `gpt-4o-mini` stays fully configured (same `openai_api_key`/`openai_api_base` as today) and simply becomes reachable only via explicit selection instead of by default.

### 4. Refresh the registry against the live Anthropic API before relying on `claude-sonnet-5`

`claude-sonnet-5` does not exist in today's `models` table or in the bundled `ruby_llm` 1.16.0 gem registry (confirmed: the newest entry is `claude-sonnet-4-6`). `RubyLLM::Providers::Anthropic::Models` fetches `v1/models` live, so once `ANTHROPIC_API_KEY` is set, `Model.refresh!` should pull `claude-sonnet-5`'s real metadata into the DB. This needs to run (once, as part of deploying this change) before `default_model` resolution is exercised in production — otherwise `Models.resolve` raises `ModelNotFoundError` on the very first new chat. Confirmed no id collision: no existing `Model` row anywhere in the registry currently has `model_id: "claude-sonnet-5"` under any provider, so once the anthropic row exists, resolution is unambiguous (unlike the earlier GitHub Models change, where prefixing `openai/gpt-4o-mini` collided with OpenRouter's identical naming convention — that trap doesn't apply here since `claude-sonnet-5` is a bare Anthropic-native id, not a `{publisher}/{model}` string).

## Risks / Trade-offs

- **[Risk]** `Model.refresh!` hits all *configured* providers' live APIs, not just Anthropic — with a real Anthropic key now present, this is fine, but if any other dummy provider key were accidentally set at refresh time, it would pull in a large, unwanted model list. → **Mitigation**: `available_chat_models`'s provider allowlist (Decision 1) keeps the picker safe regardless of what's in the `models` table; the allowlist is the actual safety boundary, not what happens to be configured.
- **[Risk]** Anthropic billing is real and metered, unlike GitHub Models. A default-model change means every new chat with no explicit selection now costs money. → **Mitigation**: none built into this change (cost display is explicitly deferred); flagged here so it's a known, accepted trade-off rather than a surprise.
- **[Risk]** If `Model.refresh!` is not run before deploy (or if Anthropic's API stops reporting `claude-sonnet-5` under that exact id), the first new chat with the default model raises `RubyLLM::ModelNotFoundError` end-to-end. → **Mitigation**: tasks.md sequences the refresh before the config change goes live; the live-key check already run in this session (`HTTP 200`, id confirmed) removes the id-mismatch risk for now.
- **[Trade-off]** Scoping via a hardcoded `CHAT_PROVIDERS` allowlist means a future third working provider requires a code change here in addition to the initializer. Accepted as simpler than provider-introspection for a two-provider list.

## Migration Plan

1. Deploy `Model.refresh!` (e.g. as a one-off `heroku run rails runner "Model.refresh!"` or a release-phase task) against the now-live Anthropic key, confirming a `claude-sonnet-5` / `anthropic` row exists afterward.
2. Ship the `default_model` change, the `available_chat_models` scoping, and the un-hidden/styled switcher together — they're small and interdependent enough that splitting them adds no safety.
3. Rollback: revert `default_model` to `"gpt-4o-mini"` and re-hide the switcher; no data migration to reverse since the `claude-sonnet-5` `Model` row is additive and harmless to leave in place.

## Open Questions

- None outstanding — the two blockers raised during exploration (exact Anthropic model id string; whether the key is actually live) were both resolved and verified before this proposal was written.
