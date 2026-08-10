## Context

`config/initializers/ruby_llm.rb` currently configures exactly one working chat provider, `anthropic` (issue #45's Anthropic-only cutover after GitHub Models' retirement). `config.deepseek_api_key` already exists in the file's "Setup - Dummy" section, reading `ENV.fetch("DEEPSEEK_API_KEY", nil)`, but no `DEEPSEEK_API_KEY` is set anywhere and no `openrouter_api_key` line exists at all. `ApplicationController::CHAT_MODELS` is an exact `[provider, model_id]` allowlist of three Anthropic models; `available_chat_models` filters `RubyLLM.models.chat_models.all` against it. `RubyLLM` 1.16.0 (the version pinned in `Gemfile`, confirmed the latest published gem release as of this proposal) ships native `DeepSeek` and `OpenRouter` provider classes (`ruby_llm/providers/deepseek.rb`, `ruby_llm/providers/openrouter.rb`) — no gem upgrade or custom provider code is needed.

Account state, checked directly against both platforms before writing this design:
- **DeepSeek** (`platform.deepseek.com`): account exists, logged in, but has **no API key** and a **$0.00 topped-up balance**. DeepSeek's platform is prepaid — a request against a $0 balance fails regardless of whether a key exists. Zero API requests in the last 30 days confirms the account has never been used.
- **OpenRouter**: no account state was checked in this session; treat as equally unprovisioned (no key, no funded credit) until confirmed otherwise.

Issue #47's research recommends, in order: DeepSeek (native RubyLLM provider, "zero-friction" on the *code* side), then Kimi K3 or GLM-5.2 via OpenRouter (a single OpenRouter key covers both, since RubyLLM's OpenRouter provider is publisher-agnostic).

The precedent for this kind of change is the archived `add-anthropic-model-switcher` change: exact `[provider, model_id]` allowlist (never provider-level), each model individually verified live before being added, a `metadata[:real_publisher]` correction for models routed through a multi-vendor aggregator, and a committed `config/ruby_llm_models.json` fallback regenerated whenever the allowlist changes. This design reuses all four mechanisms rather than inventing new ones.

### Update — live verification complete (issues #60, #54)

Both accounts are now provisioned and funded (#60), and all three candidate model ids have been confirmed live (#54) — via a real chat completion in every case, not just a catalog listing:

- **DeepSeek** (`GET /v1/models`, then a real completion): the account no longer exposes a `deepseek-chat` alias. Two live chat models were returned instead — **`deepseek-v4-flash`** and **`deepseek-v4-pro`** — both under `owned_by: "deepseek"`. A completion against `deepseek-v4-flash` succeeded. **Which of the two becomes the `CHAT_MODELS` entry is still open** — see Open Questions.
- **Kimi K3** (OpenRouter `/api/v1/models`, then a real completion): confirmed as **`moonshotai/kimi-k3`**, exactly the example form Decision 3 guessed. Completion succeeded and was billed ($0.00054), proving funded credit.
- **GLM-5.2** (OpenRouter `/api/v1/models`, then a real completion): confirmed as **`z-ai/glm-5.2`**, also exactly the guessed form. Completion succeeded and was billed ($0.00007632).

Neither OpenRouter model needs to be deferred — both are reachable on the funded tier, so the "defer if unreachable" branch of Decision 3 / tasks.md §2.4 doesn't apply.

## Goals / Non-Goals

**Goals:**
- Provision a real, funded DeepSeek API key and a real, funded OpenRouter API key — this is a genuine prerequisite, not a formality, given the confirmed $0 balance / no-key state.
- Add DeepSeek's native chat model to `CHAT_MODELS`, verified live against DeepSeek's own `v1/models` (or a real chat completion) before being added.
- Add Kimi K3 and/or GLM-5.2 to `CHAT_MODELS` via the `openrouter` provider, each verified live against OpenRouter's model catalog / a real completion before being added.
- Keep `default_model` at `claude-sonnet-5` — this change only widens the switcher.
- Correctly label OpenRouter-routed models by their real publisher (Moonshot AI, Zhipu), reusing the `metadata[:real_publisher]` pattern from the GitHub Models era rather than inventing a new mechanism.
- Regenerate `config/ruby_llm_models.json` so the test-environment fallback registry includes the new models.

**Non-Goals:**
- Changing `default_model` away from `claude-sonnet-5`.
- Re-adding GitHub Models or any OpenAI/Mistral routing — those stay retired per issue #45.
- Adding every open-weight model the issue's research table mentions (Kimi K2.6, Kimi K2, GLM-5, DeepSeek-V3.2/V4 as a "taste test") — only DeepSeek's current native chat model plus Kimi K3 and/or GLM-5.2 are in scope, matching the issue's stated rollout order. Additional models are a follow-up, same discipline as this change.
- Switching a model on an already-started chat, or surfacing `chat.cost`/pricing UI — both remain out of scope, unchanged from the prior chat-model-selection change.
- Meta Muse Spark — explicitly excluded by the issue as closed-weight.

## Decisions

### 1. Provision credentials before writing any code (blocking, not parallel)

Both platforms are confirmed unprovisioned: DeepSeek has no key and $0 balance; OpenRouter is assumed equally unprovisioned. `Model.refresh!` and any live-verification step in tasks.md will hard-fail (`RubyLLM::ConfigurationError` or an HTTP auth error) without real, funded keys. tasks.md sequences key creation + balance top-up as literal first steps, not an assumption baked into later steps — mirroring how the original Anthropic change's Migration Plan treated "confirm the key is live" as a precondition, not a footnote.

**Alternative considered**: write all the code against `assume_model_exists`-style stubs and defer provisioning to deploy time. Rejected — the prior change's Decision 4 already demonstrated this fails: `Models.resolve` raises `ModelNotFoundError` the moment a chat is created against a model that was never actually verified live, and this repo's convention (Decision 1 of the prior change) explicitly treats "individually verified" as the safety boundary, not "configured."

### 2. DeepSeek is added under RubyLLM's native `deepseek` provider, not routed through OpenRouter

DeepSeek ships a first-class RubyLLM provider class with its own `deepseek_api_key`/`deepseek_api_base` config (already present as a config stub). Routing it through OpenRouter instead would work too (OpenRouter proxies DeepSeek models), but would needlessly give up the direct, cheaper, already-half-configured path for no benefit — and contradicts the issue's own "DeepSeek first (zero-friction)" framing, which specifically calls out the native-provider path as the reason DeepSeek goes first.

**Alternative considered**: route DeepSeek through OpenRouter alongside Kimi/GLM, for a single credential to manage. Rejected — the existing `deepseek_api_key` stub and native provider class mean there's no real credential-management savings, and it would mean paying OpenRouter's markup on DeepSeek calls for no reason.

### 3. Kimi K3 and GLM-5.2 are added under the native `openrouter` provider, registered with their OpenRouter-native ids

Both are reachable through RubyLLM's native `OpenRouter` provider class (`openrouter_api_key`/`openrouter_api_base`), which is publisher-agnostic — one key covers any model OpenRouter fronts. Register them with whatever id OpenRouter's live catalog reports (OpenRouter ids are conventionally `{publisher-slug}/{model-slug}`) — the **exact** ids are confirmed against OpenRouter's `/api/v1/models` during implementation, not assumed from naming convention alone, matching this repo's verification discipline. If either model isn't yet listed on OpenRouter at implementation time, that model is deferred rather than added speculatively.

**Confirmed (issue #54)**: both ids are live and match the guessed convention exactly — `moonshotai/kimi-k3` and `z-ai/glm-5.2`. Each was verified with a real, billed chat completion (not just a catalog listing), so neither needs to be deferred.

**Alternative considered**: pick one of Kimi K3 / GLM-5.2 only, deferring the other. Rejected as a default — the issue names both as the "then" step of the rollout with no stated preference between them, and OpenRouter's single-credential model means adding both costs nothing beyond the extra verification step. (If live verification during implementation shows only one is actually reachable on this account/tier, that alone is a valid reason to ship one and defer the other — same posture the prior change took toward the GPT-5/o-series models that turned out to be blocked.)

### 4. Real-publisher label correction is reinstated via the same `metadata[:real_publisher]` mechanism, not rebuilt from scratch

The prior change's `chat_model_provider_label`/`chat_model_label` helpers and `REAL_PUBLISHER_NAMES` map were removed when GitHub Models (and its Mistral/DeepSeek-via-OpenAI-provider rows) was dropped in issue #45 — confirmed by grep, no `real_publisher` reference remains anywhere in `app/`. This change reintroduces the same mechanism (helpers + metadata key), scoped now to OpenRouter's multi-vendor rows instead of GitHub Models'. DeepSeek-native rows need no such correction — `provider_class.name` already resolves to "Deepseek" correctly, same as Anthropic today.

**Alternative considered**: skip the label correction and let OpenRouter-routed models display as "Openrouter - Kimi K3". Rejected — this is the exact defect the prior change already fixed once for GitHub Models (Decision 7 there); reintroducing it here would be a known regression, not a new risk.

## Risks / Trade-offs

- ~~**[Risk]** OpenRouter's exact model ids for Kimi K3 / GLM-5.2 are not yet confirmed live~~ **Resolved (#54)**: both confirmed via live `/api/v1/models` and a real billed completion — `moonshotai/kimi-k3`, `z-ai/glm-5.2`.
- ~~**[Risk]** DeepSeek's $0 balance means even a successful key creation doesn't unblock verification~~ **Resolved (#60)**: account funded, confirmed with a real completion against `deepseek-v4-flash`. Note the model id itself moved — `deepseek-chat` is no longer listed; see the Open Questions entry on `deepseek-v4-flash` vs. `deepseek-v4-pro`.
- **[Risk]** `RubyLLM::Models.instance` is a per-process memoized singleton (documented risk from the prior change) — any already-running dev server or production dyno won't see new `Model` rows from `Model.refresh!` until restarted. → **Mitigation**: same as before — tasks.md and the Migration Plan call out the restart step explicitly.
- **[Trade-off]** Adding a fourth and fifth model to `CHAT_MODELS` means the switcher now spans three separate credential surfaces (Anthropic, DeepSeek, OpenRouter) instead of one — three things that can independently go down or exhaust a rate limit. Accepted: each is individually verified before being listed, and the exact-allowlist mechanism (unchanged from the prior design) is what keeps a broken provider from silently exposing broken models, not provider-count minimization.
- **[Trade-off]** Both new providers are metered/prepaid, same category as the original Anthropic switch — but unlike Anthropic (billed centrally, already budgeted), DeepSeek and OpenRouter are brand-new spend lines with no existing budget relationship. Flagged here as a cost-owner decision, not something this design can resolve.

## Migration Plan

1. Create and fund a DeepSeek API key (`platform.deepseek.com/api_keys`, then top up balance) and an OpenRouter API key with funded credit. Set `DEEPSEEK_API_KEY` and `OPENROUTER_API_KEY` in every environment (local `.env`, Heroku config) before proceeding.
2. Promote `config.deepseek_api_key` from "Dummy" to "Working" in `config/initializers/ruby_llm.rb`; add `config.openrouter_api_key = ENV.fetch("OPENROUTER_API_KEY", nil)` alongside it.
3. Verify DeepSeek's chat model and the intended OpenRouter model(s) live (a real chat completion or a live `v1/models`/`/api/v1/models` listing) before touching `CHAT_MODELS`.
4. Add the verified `[provider, model_id]` pairs to `ApplicationController::CHAT_MODELS`; add the OpenRouter `real_publisher` metadata and the `chat_model_provider_label`/`chat_model_label` helper logic (or restore it from the prior change's git history, adapted to `openrouter` instead of `openai`-via-GitHub-Models).
5. Run `Model.refresh!` (locally, then in production via a one-off dyno run) so the new rows have real pricing/context-window/capabilities metadata; regenerate and commit `config/ruby_llm_models.json` via `RubyLLM.models.save_to_json`.
6. **Restart the production dynos** (or ensure this deploy happens after step 5 in the same release) — the per-process registry cache means an already-running dyno won't see new `Model` rows otherwise.
7. Rollback: remove the new entries from `CHAT_MODELS`, revert the initializer changes, and re-run `Model.refresh!`/regenerate `config/ruby_llm_models.json` to drop the new rows if desired (they're additive and harmless to leave in place otherwise). No data migration to reverse.

## Open Questions

- ~~Exact OpenRouter model ids for Kimi K3 and GLM-5.2~~ — **Resolved (#54)**: `moonshotai/kimi-k3`, `z-ai/glm-5.2`.
- **New, replaces the resolved question above**: DeepSeek no longer lists a `deepseek-chat` alias — the live account shows `deepseek-v4-flash` and `deepseek-v4-pro` instead. Which one becomes the `CHAT_MODELS` entry is undecided: `flash` is the conventional lower-cost/lower-latency default (and is what tasks.md §2.1's verification completion used), while `pro` is presumably the higher-capability tier. Needs a decision before tasks.md §3.1.
- ~~Whether both Kimi K3 and GLM-5.2 should ship together or Kimi K3 first~~ — **Resolved (#54)**: both are reachable on the funded tier, no staging needed.
- Who owns the DeepSeek/OpenRouter billing relationship going forward (cost-owner decision, not a technical blocker to this change).
