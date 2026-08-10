## Why

The chat model switcher is Anthropic-only by design (`chat-model-selection` spec, issue #45) after GitHub Models' free inference endpoint was retired. Issue #47 asks for open-weight models to be added back in, this time through real, dedicated credentials rather than a shared aggregator: research in the issue (EQ-Bench Creative Writing v3 + Arena Text/Creative + r/LocalLLaMA sentiment) recommends DeepSeek for its distinctive, "less corporate" prose and native zero-friction RubyLLM support, and Kimi K3 / GLM-5.2 for creative-writing quality approaching Claude Opus 5 at a fraction of the cost — both reachable through RubyLLM's native OpenRouter provider under a single key. RubyLLM 1.16.0 (already the version pinned in `Gemfile`, and confirmed the latest published gem release) ships native `DeepSeek` and `OpenRouter` provider classes, so no gem upgrade is required.

## What Changes

- Provision real credentials for both new providers before any code ships: create a DeepSeek API key (the account currently has none and a $0 topped-up balance — DeepSeek's platform is prepaid, so a request against a $0 balance fails regardless of key) and an OpenRouter API key with funded credit.
- Configure `deepseek_api_key` (already stubbed as a "Dummy" entry in `config/initializers/ruby_llm.rb`, moved to "Working") and add a new `openrouter_api_key` entry, both read from `ENV`.
- **BREAKING** (to the current spec, not to running behavior): loosen the `chat-model-selection` requirement "SHALL NOT configure or expose any chat provider other than Anthropic" to allow an exact, individually-verified allowlist of DeepSeek and OpenRouter chat models alongside the existing Anthropic ones. `default_model` stays `claude-sonnet-5` — this only widens the switcher, it does not change what an unspecified chat resolves to.
- Verify each candidate model live before adding it to `ApplicationController::CHAT_MODELS`, matching this repo's existing convention (no auto-discovery, no provider-level allowlist — see the `add-anthropic-model-switcher` precedent): DeepSeek's chat model(s) via `deepseek_api_key`, and Kimi K3 and/or GLM-5.2 via `openrouter_api_key`, using OpenRouter's own model id format (e.g. `moonshotai/kimi-k3`, `z-ai/glm-5.2` — exact ids to be confirmed against OpenRouter's live catalog during implementation).
- Correct provider display labels for the OpenRouter-routed models the same way the prior change handled GitHub Models' multi-vendor routing (`chat_model_provider_label`/`chat_model_label`), since OpenRouter fronts multiple publishers (Moonshot AI, Zhipu) under one `provider: "openrouter"` registry tag.
- Refresh and re-commit `config/ruby_llm_models.json` (the empty-DB/test fallback registry) to include the newly-added models.
- Out of scope: Meta Muse Spark (closed-weight, explicitly excluded by the issue), any model not individually verified live, switching a model on an already-started chat, and cost/pricing UI.

## Capabilities

### New Capabilities
(none)

### Modified Capabilities
- `chat-model-selection`: the provider allowlist widens from Anthropic-only to Anthropic + DeepSeek + OpenRouter (exact `[provider, model_id]` entries only); the "no other chat provider configured or exposed" requirement and its scenarios are revised to name the new providers explicitly while keeping the same verification bar and the same fixed-at-creation, exact-allowlist mechanics.

## Impact

- **Config**: `config/initializers/ruby_llm.rb` (`deepseek_api_key` promoted to "Working", new `openrouter_api_key`), `config/ruby_llm_models.json` (regenerated).
- **Code**: `app/controllers/application_controller.rb` (`CHAT_MODELS` allowlist grows; `chat_model_provider_label`/`chat_model_label` gain an OpenRouter real-publisher mapping).
- **Data**: `models` table gains DeepSeek and OpenRouter rows via `Model.refresh!` once both keys are live.
- **External accounts**: a DeepSeek API key must be created and the account balance topped up; an OpenRouter account/key must be created and funded. Neither exists today — this is a real provisioning dependency, not just a config change.
- **Cost**: both new providers are metered/prepaid, same category of change as the original Anthropic default-model switch.
- **No changes** to `chats/show.html.erb`, `ChatResponseJob`, `GenerationJob`, `StructuredExtraction`, or the `default_model` value — they already resolve generically and Claude Sonnet 5 remains the default.
