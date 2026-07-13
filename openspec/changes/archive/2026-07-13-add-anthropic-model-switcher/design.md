## Context

`config/initializers/ruby_llm.rb` configures RubyLLM (`use_new_acts_as = true`), which backs `RubyLLM.models` with an ActiveRecord-mirrored registry (`Model` / `acts_as_model`, `Chat` / `acts_as_chat`) instead of the gem's bundled static JSON. `available_chat_models` (`app/controllers/application_controller.rb`) currently returns every chat-capable model across every provider RubyLLM knows about — roughly 1350 rows spanning openai, anthropic, gemini, deepseek, mistral, perplexity, xai, azure, bedrock, vertexai, openrouter, ollama, and gpustack. Only `openai` (routed through GitHub Models, not real OpenAI) has ever had a working key; `anthropic` was a `nil`-valued stub. `ANTHROPIC_API_KEY` is now set on Heroku and confirmed live (`HTTP 200` against `api.anthropic.com/v1/models`, and `claude-sonnet-5` is confirmed to be the exact id Anthropic reports).

The model `<select>` needed for a switcher already exists in `app/views/chats/_form.html.erb`, wired to `@chat_models` / `@selected_model`, but is wrapped in `class="mb-6 hidden"` and was never scoped to working providers — presumably hidden for exactly the reason above (picking an unconfigured provider crashes with `RubyLLM::ConfigurationError`).

A prior change (see `config/initializers/ruby_llm.rb`) added a `RubyLLM::Providers::OpenAI` prepend that rewrites the outgoing `model` field to carry a publisher prefix (`openai/gpt-4o-mini`) only when `openai_api_base` points at `models.github.ai`, and — critically for this change — leaves any id that *already* contains a `/` untouched. That was written as a workaround for GitHub Models' endpoint contract; this change leans on that same untouched-passthrough behavior to reach non-OpenAI models through GitHub Models too (Decision 6), which wasn't anticipated when the patch was written but works correctly as-is.

## Goals / Non-Goals

**Goals:**
- Make Claude Sonnet 5 (`anthropic` provider) the default model for new chats.
- Keep `gpt-4o-mini` (`openai` provider, via GitHub Models) fully available as a non-default option.
- Give users a working model switcher when starting a new chat, scoped to an exact, individually-verified set of models — not merely "provider is configured," since that turned out not to be a sufficient safety boundary (see Decision 1).
- Surface the multi-vendor reality of GitHub Models: it isn't an OpenAI-only proxy, and the switcher should offer real, verified models from other publishers (Mistral, DeepSeek) reachable through the same `GITHUB_TOKEN`, correctly labeled with their real publisher rather than "OpenAI".
- Ensure the registry has real metadata for `claude-sonnet-5` (pricing, context window, capabilities) rather than a placeholder stub, so `default_model_display_name` and the switcher's labels are accurate.

**Non-Goals:**
- Switching the model on an already-started chat (`chats/show.html.erb`). The model is fixed at `Chat.create!` time, as it is today; `RubyLLM::ActiveRecord::ChatMethods#with_model` exists in the gem but isn't wired to any controller action here.
- Surfacing `chat.cost` or any cost/pricing UI. Deferred explicitly by the user.
- Un-hiding or exposing any provider other than `openai` and `anthropic` (gemini, perplexity, xai, azure, bedrock, vertexai, openrouter, ollama, gpustack stay excluded from the picker; their `Model` rows are untouched). Mistral and DeepSeek models *are* now exposed, but only the two specific ones verified against GitHub Models — not RubyLLM's native `mistral`/`deepseek` providers, which stay unconfigured (no real Mistral/DeepSeek API keys exist).
- Changing GitHub Models' payload-prefixing patch or endpoint.
- Exposing every model GitHub Models lists. Its catalog has 37 entries; only 4 (beyond Claude Sonnet 5) were verified live and added. The GPT-5 family and o1/o3/o4 reasoning tier are deliberately excluded — confirmed blocked (`400`/`403`) on this token/tier, not merely untested.

## Decisions

### 1. Scope `available_chat_models` by an exact `[provider, model_id]` allowlist (revised from a provider-only allowlist)

**Originally**: an explicit provider allowlist —

```ruby
CHAT_PROVIDERS = %w[openai anthropic].freeze

def available_chat_models
  RubyLLM.models.chat_models.all
         .select { |model| CHAT_PROVIDERS.include?(model.provider.to_s) }
         .sort_by { |model| [ model.provider.to_s, model.name.to_s ] }
end
```

rather than checking each provider's `configured?` — simpler, matched how the initializer already documents "Working" vs "Dummy" providers, and failed safe against an accidentally-set dummy key.

**Revised, after hands-on verification in the browser surfaced two kinds of false positives a provider allowlist can't catch**:

```ruby
CHAT_MODELS = [
  %w[anthropic claude-sonnet-5],
  %w[openai gpt-4o],
  %w[openai gpt-4o-mini],
  %w[openai gpt-4.1],
  %w[openai mistral-ai/mistral-small-2503],
  %w[openai deepseek/deepseek-v3-0324]
].freeze

def available_chat_models
  RubyLLM.models.chat_models.all
         .select { |model| CHAT_MODELS.include?([ model.provider.to_s, model.id ]) }
         .sort_by { |model| [ model.provider.to_s, model.name.to_s ] }
end
```

The two false positives:
- `RubyLLM.models.chat_models` tags plenty of non-chat models as `type: "chat"` regardless of provider — `dall-e-3`, `whisper-1`, `tts-1`, `sora-2`, and other image/audio/video models the registry doesn't distinguish from real chat models. A provider allowlist can't exclude these; they're openai-provider rows too.
- `gpt-4o`/`gpt-4o-mini` also exist under the `azure` provider with the identical bare id (RubyLLM's Azure provider mirrors OpenAI deployment names). A provider allowlist can't tell the working `openai` row apart from the unconfigured `azure` one when both share the same id — this rendered as a literal visible duplicate ("OpenAI - GPT-4o mini" and "Azure - GPT-4o mini") in the switcher.

Pairing exact `[provider, model_id]` avoids both, and is also what makes it safe to add cross-publisher models registered under the `openai` provider for credential-routing reasons (see Decision 6) — there's no risk of a stray `mistral-something` row leaking in just because it happens to share the `openai` provider tag.

**Alternative considered**: iterate providers and call `provider_class.configured?(config)`. Rejected — doesn't address either false positive above, since both `dall-e-3` and the `azure` duplicate are associated with tags/providers that would themselves report as configured or at least indistinguishable by that check alone.

### 2. Un-hide the existing `<select>` rather than building a new component

The select, its `options_for_select` wiring against `@chat_models`/`@selected_model`, and the controller plumbing (`chats_controller.rb#new` sets `@selected_model = params[:model]`; `#create` passes `model: params.dig(:chat, :model).presence` into `Chat.create!`) already exist and already work — they were just never scoped or shown. This change removes `hidden` from the wrapping `div`, gives it a real `cf-label`, and confirms it renders per `DESIGN.md` (`.cf-select`-equivalent styling, no shadows, matches the rest of the composer). No new controller logic is needed for the "pick a model" half of this change.

### 3. `default_model` becomes `claude-sonnet-5`, unconditionally (no env-based toggle)

`RubyLLM.config.default_model = "claude-sonnet-5"` in the initializer, replacing `"gpt-4o-mini"`. This is a direct, explicit decision from the user — not something to hide behind a feature flag or environment check. `gpt-4o-mini` stays fully configured (same `openai_api_key`/`openai_api_base` as today) and simply becomes reachable only via explicit selection instead of by default.

### 4. Refresh the registry against the live Anthropic API before relying on `claude-sonnet-5`

`claude-sonnet-5` does not exist in today's `models` table or in the bundled `ruby_llm` 1.16.0 gem registry (confirmed: the newest entry is `claude-sonnet-4-6`). `RubyLLM::Providers::Anthropic::Models` fetches `v1/models` live, so once `ANTHROPIC_API_KEY` is set, `Model.refresh!` should pull `claude-sonnet-5`'s real metadata into the DB. This needs to run (once, as part of deploying this change) before `default_model` resolution is exercised in production — otherwise `Models.resolve` raises `ModelNotFoundError` on the very first new chat. Confirmed no id collision: no existing `Model` row anywhere in the registry currently has `model_id: "claude-sonnet-5"` under any provider, so once the anthropic row exists, resolution is unambiguous (unlike the earlier GitHub Models change, where prefixing `openai/gpt-4o-mini` collided with OpenRouter's identical naming convention — that trap doesn't apply here since `claude-sonnet-5` is a bare Anthropic-native id, not a `{publisher}/{model}` string).

### 5. A project-owned `config/ruby_llm_models.json` replaces the gem's bundled registry as the empty-DB fallback

Discovered while implementing Decision 3: this app never seeds the `models` table in the test environment (there's no `test/fixtures/` at all), so `RubyLLM::Models.load_models` has always silently fallen back to the *gem's own bundled* `models.json` whenever `ActiveRecordSource#read` returns an empty array — which is every test run. That file only tracks whatever the installed `ruby_llm` gem version happened to ship with (`claude-sonnet-4-6` at the time of this change), so setting `default_model` to `claude-sonnet-5` broke 52 tests with `RubyLLM::ModelNotFoundError` the moment it was tried, even though the *development* DB (seeded, non-empty) resolved it fine.

The fix: set `config.model_registry_file` to a new committed `config/ruby_llm_models.json`, generated via `RubyLLM.models.save_to_json` (the exact pairing the gem's own `models.rake` task and its `ModelNotFoundError` message both point at), scoped by provider (`openai`, `anthropic`) rather than resurrecting the full ~1350-model catalog as a committed fallback. Scoping by provider here (broader than the exact-id `CHAT_MODELS` allowlist in Decision 1) is deliberate — this file backs the *entire* registry lookup in test, not just the switcher, so it needs every `openai`/`anthropic` model any test might reference, not only the six currently allowlisted for the UI. This makes the empty-DB fallback something the app actually owns and versions, instead of a moving target tied to whatever gem version is installed.

**Alternative considered**: seed the test `models` table directly (fixtures, or a `Model.refresh!` call in test setup). Rejected — `Model.refresh!` makes live HTTP calls to provider APIs, which is non-deterministic and requires network + real keys in CI; this app also has no fixtures infrastructure at all for any table, so introducing one just for this table would be inconsistent with its existing test conventions.

**Trade-off**: this file needs to be regenerated (`RubyLLM.models.save_to_json` after `Model.refresh!`) whenever a new model this app cares about ships from either provider — one more file to remember to update, in exchange for tests no longer depending on gem version. Confirmed still true: it was regenerated twice more in this change, once when the two GitHub-Models-routed rows were added (Decision 6) and once when their display names were cleaned up (Decision 7).

### 6. GitHub Models is a multi-vendor aggregator — verify and allowlist specific non-OpenAI models rather than assuming OpenAI-only

Prompted by a direct question ("is gpt-4o also reachable, and what else?"), the full GitHub Models catalog was pulled (`GET https://models.github.ai/catalog/models`, current `GITHUB_TOKEN`): 37 models across OpenAI, Cohere, DeepSeek, Meta, Mistral AI, and Microsoft. Each candidate was verified with a real chat-completion request before being added, not just catalog presence — catalog listing doesn't imply this token/tier can actually use it:

- **Reachable (added to `CHAT_MODELS`)**: `openai/gpt-4o`, `openai/gpt-4o-mini`, `openai/gpt-4.1`, `mistral-ai/mistral-small-2503`, `deepseek/deepseek-v3-0324`.
- **Reachable but not added** (out of scope for this change, not because they don't work): `deepseek/deepseek-r1*`, `meta/llama-*`, `microsoft/phi-4*`, `cohere/cohere-command-a`, `mistral-ai/codestral-2501`, `mistral-ai/ministral-3b`, `mistral-ai/mistral-medium-2505` — all returned real replies when tested but weren't part of the requested set.
- **Listed in the catalog but blocked for this token** (`400 unavailable_model` or `403 Forbidden`, not untested): `openai/gpt-5`, `gpt-5-mini`, `gpt-5-nano`, `gpt-5-chat`, `o4-mini`, `o1`, `o1-mini`, `o1-preview`, `o3`, `o3-mini`. Excluding these is a verified constraint, not caution.

Since `mistral-ai/mistral-small-2503` and `deepseek/deepseek-v3-0324` have no dedicated `mistral_api_key`/`deepseek_api_key` configured (RubyLLM does have native `Mistral`/`DeepSeek` provider classes, both subclassing `OpenAI` the same way `Azure` does — but pointing *those* at GitHub Models too would mean reconfiguring two more credential slots and auditing whether `GithubModelsModelPrefix`'s `config.openai_api_base` check needs to become provider-instance-aware, since it currently reads a single hardcoded config field regardless of which provider subclass is asking). The simpler path: register both under the `openai` provider (our one GitHub Models credential slot) with the full `publisher/model` id GitHub Models expects verbatim (`mistral-ai/mistral-small-2503`, `deepseek/deepseek-v3-0324`). Since `GithubModelsModelPrefix` only prefixes ids that *don't* already contain a `/`, these pass through completely unmodified — verified end-to-end through `RubyLLM.chat` and a full `Chat#complete` round-trip, not just raw `curl`.

**Alternative considered**: configure real `mistral_api_key`/`deepseek_api_key` pointing at GitHub Models, using RubyLLM's native `Mistral`/`DeepSeek` provider classes so the registry's `provider` field is truthful. Rejected for now — would require making the prefix patch check the *instance's own* `api_base` instead of the hardcoded `config.openai_api_base` (a real, if small, correctness gap in the existing patch that this alternative would have needed to fix first), for no behavioral difference to the user. Accepted the `provider: "openai"` modeling quirk instead, and fixed its one real consequence (display labeling) via Decision 7.

### 7. Correct the displayed provider for credential-routed models via `metadata[:real_publisher]`, not the registry's `provider` field

Decision 6's `mistral-ai/...`/`deepseek/...` rows are registered under `provider: "openai"`. `RubyLLM::Model::Info#label` always renders `"<provider_class.name> - <name>"`, so these showed as **"OpenAI - Mistral Small 3.1"** and **"OpenAI - DeepSeek-V3-0324"** — factually wrong, and caught visually (not by a test — none existed yet for this).

Fix: each row's `metadata` carries `real_publisher: "mistral-ai"` / `"deepseek"` at creation time. Two new `ApplicationController` helpers — `chat_model_provider_label(model)` (reads `metadata[:real_publisher]` if present, via a small `REAL_PUBLISHER_NAMES` display-name map, else falls back to `model.provider_class&.name || model.provider`) and `chat_model_label(model)` (combines it with `model.name`) — replace direct `model.label` / `model.provider_class&.name` calls everywhere a model's provider is shown: the switcher (`chats/_form.html.erb`) **and** the `/models` registry pages (`models/_model.html.erb`, `models/show.html.erb`), which had the identical bug and weren't part of the original request but were the same root cause.

For every model *without* a `real_publisher` (i.e. everything except the two GitHub-Models-routed exceptions), the fallback path is exactly RubyLLM's own existing behavior — `provider_class.name` already correctly resolves `"OpenAI"` and `"Anthropic"` for those, confirmed directly rather than assumed.

A regression test (`test/controllers/models_controller_test.rb`) asserts the real publisher renders — and was verified to actually catch the bug by temporarily reverting the fix and confirming the test failed with `Expected: "Mistral" / Actual: "OpenAI"` before restoring it.

## Risks / Trade-offs

- **[Risk]** `Model.refresh!` hits all *configured* providers' live APIs, not just Anthropic — with a real Anthropic key now present, this is fine, but if any other dummy provider key were accidentally set at refresh time, it would pull in a large, unwanted model list. → **Mitigation**: `available_chat_models`'s exact `[provider, model_id]` allowlist (Decision 1) keeps the picker safe regardless of what's in the `models` table; the allowlist is the actual safety boundary, not what happens to be configured or fetched.
- **[Risk]** Anthropic billing is real and metered, unlike GitHub Models. A default-model change means every new chat with no explicit selection now costs money. → **Mitigation**: none built into this change (cost display is explicitly deferred); flagged here so it's a known, accepted trade-off rather than a surprise.
- **[Risk]** If `Model.refresh!` is not run before deploy (or if Anthropic's API stops reporting `claude-sonnet-5` under that exact id), the first new chat with the default model raises `RubyLLM::ModelNotFoundError` end-to-end. → **Mitigation**: tasks.md sequences the refresh before the config change goes live; the live-key check already run in this session (`HTTP 200`, id confirmed) removes the id-mismatch risk for now.
- **[Risk]** RubyLLM's model registry (`RubyLLM::Models.instance`) is a per-process memoized singleton. Any already-running process (dev server, production dyno) that loaded it before new `Model` rows exist won't see them until restarted — discovered directly when local `bin/dev`, started before the Mistral/DeepSeek rows were created, kept showing the old 3-model list until restarted. → **Mitigation**: tasks.md and the Migration Plan below call this out explicitly as a required step, not an assumed side effect of deploying.
- **[Risk]** The Mistral/DeepSeek rows being registered under `provider: "openai"` (Decision 6) is a real modeling quirk — anyone querying the `models` table directly (not through `chat_model_provider_label`) will see the wrong provider. → **Mitigation**: `metadata[:real_publisher]` is the source of truth and is documented in the `CHAT_MODELS` comment; the label-correction helpers (Decision 7) are the only sanctioned read path for display.
- **[Trade-off]** Scoping via a hardcoded `CHAT_MODELS` allowlist (an exact list of individually-verified models, not a provider or "is configured" check) means every future model addition is a deliberate, verified code change here — no auto-discovery. Accepted: the two false positives in Decision 1 demonstrate why auto-discovery isn't safe for this app's registry as-is.

## Migration Plan

1. Deploy `Model.refresh!` (e.g. as a one-off `heroku run rails runner "Model.refresh!"` or a release-phase task) against the now-live Anthropic key, confirming a `claude-sonnet-5` / `anthropic` row exists afterward; also create the `mistral-ai/mistral-small-2503` and `deepseek/deepseek-v3-0324` rows the same way they were created locally (`Model.find_or_create_by!`, since `Model.refresh!` can't discover GitHub Models' catalog schema automatically).
2. **Restart the production dynos after step 1**, or ensure the deploy that ships the code changes happens after step 1 in the same release — RubyLLM's per-process registry cache (see Risks) means a dyno that was already running won't see new `Model` rows otherwise.
3. Ship the `default_model` change, the `available_chat_models` allowlist, the un-hidden/styled switcher, and the label-correction helpers together — they're small and interdependent enough that splitting them adds no safety.
4. Rollback: revert `default_model` to `"gpt-4o-mini"` and re-hide the switcher; no data migration to reverse since every `Model` row added by this change is additive and harmless to leave in place.

## Open Questions

- None outstanding — the two blockers raised during exploration (exact Anthropic model id string; whether the key is actually live) were both resolved and verified before this proposal was written.
