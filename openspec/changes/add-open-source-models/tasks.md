## 1. Provision credentials (blocking — no code depends on this being skipped)

- [x] 1.1 Create a DeepSeek API key at `platform.deepseek.com/api_keys` (currently empty) and top up the account's prepaid balance (currently $0.00)
- [x] 1.2 Create an OpenRouter account/API key and fund it with credit
- [x] 1.3 Set `DEEPSEEK_API_KEY` and `OPENROUTER_API_KEY` locally (`.env`) and confirm both resolve via `ENV.fetch` in a Rails console
- [x] 1.4 Set `DEEPSEEK_API_KEY` and `OPENROUTER_API_KEY` on Heroku (`heroku config:set`)

## 2. Verify candidate models live, before touching the allowlist

- [x] 2.1 Confirm DeepSeek's native chat model id via a real request against DeepSeek's `v1/models` (or a real chat completion) using the new key — `deepseek-chat` is gone; live account returns `deepseek-v4-flash` and `deepseek-v4-pro`, completion-tested against `deepseek-v4-flash`. Which one ships is still open (see design.md Open Questions).
- [x] 2.2 Confirm Kimi K3's exact OpenRouter model id via OpenRouter's live `/api/v1/models` catalog (or a real chat completion) — confirmed `moonshotai/kimi-k3`, completion-tested and billed.
- [x] 2.3 Confirm GLM-5.2's exact OpenRouter model id the same way — confirmed `z-ai/glm-5.2`, completion-tested and billed.
- [x] 2.4 If either Kimi K3 or GLM-5.2 is not reachable on the funded tier, note it as deferred (mirrors the prior change's GPT-5/o-series exclusion) rather than adding it speculatively — both reachable on the funded tier, neither deferred.

## 3. Configure providers

- [x] 3.1 In `config/initializers/ruby_llm.rb`, move `config.deepseek_api_key` from the "Setup - Dummy" section to "Setup - Working", with a comment recording the verification done in Task 2.1
- [x] 3.2 Add `config.openrouter_api_key = ENV.fetch("OPENROUTER_API_KEY", nil)` to the "Setup - Working" section, with a comment recording the verification done in Tasks 2.2–2.3
- [x] 3.3 Confirm `config.default_model` is untouched (`"claude-sonnet-5"`)

## 4. Expand the allowlist and fix provider labels

- [x] 4.1 Add the verified `[provider, model_id]` pairs from Task 2 to `ApplicationController::CHAT_MODELS`
- [x] 4.2 Reintroduce `metadata[:real_publisher]` tagging for the OpenRouter-routed rows (Kimi → Moonshot AI, GLM → Zhipu), adapting the mechanism the prior `add-anthropic-model-switcher` change built for GitHub Models (removed in issue #45 — confirmed no trace remains in `app/`)
- [x] 4.3 Reintroduce `chat_model_provider_label`/`chat_model_label` helpers on `ApplicationController`, reading `metadata[:real_publisher]` when present and falling back to `model.provider_class&.name || model.provider` otherwise
- [x] 4.4 Update `app/views/chats/_form.html.erb` (already uses `chat_model_label`) and `app/views/models/_model.html.erb` / `app/views/models/show.html.erb` to use the label helpers if they don't already

## 5. Refresh registry data

- [ ] 5.1 Run `Model.refresh!` locally against the now-live DeepSeek and OpenRouter keys; confirm rows exist for every id added in Task 4.1
- [ ] 5.2 Regenerate `config/ruby_llm_models.json` via `RubyLLM.models.save_to_json` and commit it
- [ ] 5.3 Restart the local dev server (`bin/dev`) to pick up the new `Model` rows (per-process registry cache — confirmed gotcha from the prior change)

## 6. Verify end-to-end

- [ ] 6.1 Start a new chat, confirm the switcher lists all three DeepSeek/OpenRouter entries alongside the three Anthropic ones, with correct publisher labels
- [ ] 6.2 Select DeepSeek, send a message, confirm a real reply with no `RubyLLM::ConfigurationError`
- [ ] 6.3 Select Kimi K3 (if shipped), send a message, confirm a real reply
- [ ] 6.4 Select GLM-5.2 (if shipped), send a message, confirm a real reply
- [ ] 6.5 Confirm an unspecified new chat still defaults to `claude-sonnet-5`
- [ ] 6.6 Confirm the `/models` registry pages show correct publisher labels for the new rows

## 7. Deploy

- [ ] 7.1 Run `Model.refresh!` in production (one-off dyno run) against the live keys, confirming the new rows exist
- [ ] 7.2 Deploy the code changes in the same release as (or strictly after) Task 7.1
- [ ] 7.3 Restart production dynos if the deploy itself doesn't already cycle them
- [ ] 7.4 Smoke-test Task 6's scenarios in production
