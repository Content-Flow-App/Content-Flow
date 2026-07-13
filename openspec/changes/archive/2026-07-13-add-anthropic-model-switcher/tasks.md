## 1. Registry

- [x] 1.1 Confirm `ANTHROPIC_API_KEY` is set and live on Heroku (already verified in exploration: `HTTP 200` against `api.anthropic.com/v1/models`, `claude-sonnet-5` present)
- [x] 1.2 Run `Model.refresh!` locally against dev DB — confirmed a `claude-sonnet-5` / `anthropic` row exists with real pricing/context-window/capabilities data. **Production refresh (`heroku run rails runner "Model.refresh!" --app content-flow-app`) still pending** — holding off until this change actually ships, per the task's own "once this ships" framing; see note below.
- [x] 1.3 Confirm no other provider's row collides on `model_id: "claude-sonnet-5"` (confirmed: only one row, provider `anthropic`)

## 2. Configuration

- [x] 2.1 Change `RubyLLM.config.default_model` to `"claude-sonnet-5"` in `config/initializers/ruby_llm.rb`
- [x] 2.2 Leave `openai_api_key` / `openai_api_base` (GitHub Models) and the existing `GithubModelsModelPrefix` payload patch untouched — verified with `git diff`, only the `anthropic`/`default_model` lines and comments changed
- [x] 2.3 Add a comment noting `claude-sonnet-5` is the live Anthropic Console model id (not a placeholder), matching the style of the existing "Setup - Working" comments
- [x] 2.4 (found during implementation) Point `config.model_registry_file` at a new committed `config/ruby_llm_models.json` (scoped to `openai`/`anthropic`), since the test DB's `models` table is empty by design and was silently falling back to the `ruby_llm` gem's own bundled registry, which doesn't know about `claude-sonnet-5` — this broke 52 tests with `ModelNotFoundError` until fixed. See design.md Decision 5.

## 3. Model switcher scoping

- [x] 3.1 Add a `CHAT_PROVIDERS = %w[openai anthropic].freeze` constant to `app/controllers/application_controller.rb`
- [x] 3.2 Update `available_chat_models` to filter `RubyLLM.models.chat_models.all` to `CHAT_PROVIDERS` before sorting
- [x] 3.3 Verify `ModelsController#index` still renders correctly with the narrowed list — added `test/controllers/models_controller_test.rb` (previously nonexistent) rather than only checking by hand: confirms `index` renders exactly the scoped count (158 models, down from ~1350) and lists no gemini/openrouter rows, and `show` still renders a real model
- [x] 3.4 (found during hands-on browser verification, revises 3.1/3.2) `CHAT_PROVIDERS` (provider-level allowlist) was insufficient: `RubyLLM.models.chat_models` tags non-chat models like `dall-e-3`/`whisper-1`/`tts-1`/`sora-2` as `type: "chat"` regardless of provider, and `gpt-4o`/`gpt-4o-mini` also exist under the unconfigured `azure` provider with the identical bare id — both leaked into the switcher. Replaced with `CHAT_MODELS`, an exact `[provider, model_id]` allowlist. See design.md Decision 1 (revised) for the full reasoning.

## 4. New-chat switcher UI

- [x] 4.1 Remove `hidden` from the wrapping `div` around the model `<select>` in `app/views/chats/_form.html.erb`
- [x] 4.2 Style the label/select per `DESIGN.md` (cf-label conventions, no shadows, matches the rest of the composer) — verified visually in the browser: `.cf-form-label`/`.cf-select` render correctly (Sen font, custom caret, bottom-border input, no shadows)
- [x] 4.3 Confirm `chats_controller.rb#new` (`@selected_model`, `@chat_models`) and `#create` (`model: params.dig(:chat, :model).presence`) still work unchanged against the scoped list — confirmed via DOM inspection: the "Default" option renders `value=""`, which `.presence` correctly turns into `nil`
- [x] 4.4 Confirm `default_model_display_name` (used as the select's "use default" option label) reflects Claude Sonnet 5 — confirmed in the browser: "Default: Anthropic - Claude Sonnet 5"

## 5. Expand the allowlist to GitHub Models' other verified vendors

*(New task group — not in the original plan; added after confirming GitHub Models is a multi-vendor aggregator, not OpenAI-only. See design.md Decision 6.)*

- [x] 5.1 Pull the full GitHub Models catalog (`GET https://models.github.ai/catalog/models`) with the live `GITHUB_TOKEN` — 37 models across OpenAI, Cohere, DeepSeek, Meta, Mistral AI, Microsoft
- [x] 5.2 Verify candidates with a real chat-completion request each (not just catalog presence) — confirmed working: `gpt-4o`, `gpt-4.1`, `mistral-ai/mistral-small-2503`, `deepseek/deepseek-v3-0324` (plus others not added: llama/phi/cohere/codestral/ministral/mistral-medium variants, deepseek-r1)
- [x] 5.3 Confirm the GPT-5 family and o1/o3/o4 reasoning tier are genuinely blocked for this token (`400 unavailable_model` / `403 Forbidden`), not just untested — deliberately excluded
- [x] 5.4 Create `Model` rows for `mistral-ai/mistral-small-2503` and `deepseek/deepseek-v3-0324` under provider `openai` (GitHub Models is the only credential for them), tagged `metadata[:real_publisher]`
- [x] 5.5 Add all four new models to `CHAT_MODELS`
- [x] 5.6 Regenerate `config/ruby_llm_models.json` to include the new rows
- [x] 5.7 Verify all three new models (`gpt-4.1`, mistral, deepseek) end-to-end through the real app code path — `RubyLLM.chat`, `Chat.create!(model:)` resolution, and a full `Chat#complete` round-trip (not just raw `curl`)

## 6. Correct provider display for credential-routed models

*(New task group — found while visually reviewing task group 5's work. See design.md Decision 7.)*

- [x] 6.1 Identify the bug: `mistral-ai/...`/`deepseek/...` rows display as "OpenAI - ..." since `model.label` always uses `provider_class.name`, and these rows are registered under `provider: "openai"`
- [x] 6.2 Add `REAL_PUBLISHER_NAMES` map and `chat_model_provider_label`/`chat_model_label` helpers to `ApplicationController`, reading `metadata[:real_publisher]`
- [x] 6.3 Apply the fix everywhere a model's provider is displayed: `chats/_form.html.erb` (the switcher), `models/_model.html.erb` and `models/show.html.erb` (the `/models` registry pages — same bug, not part of the original request, same root cause)
- [x] 6.4 Simplify the two rows' `name` field (drop the redundant "(via GitHub Models)" suffix now that the label correctly shows the real publisher)
- [x] 6.5 Add a regression test and verify it actually catches the bug (temporarily reverted the view fix, confirmed the test failed with `Expected: "Mistral" / Actual: "OpenAI"`, then restored it)

## 7. Verification

- [x] 7.1 Start a new chat with no model selected — confirm it resolves to `claude-sonnet-5` / `anthropic` and a real reply comes back (verified via a full `Chat#complete` round-trip against the live Anthropic key)
- [x] 7.2 Start a new chat explicitly selecting `gpt-4o-mini` — confirm it still resolves to `openai` / GitHub Models and a real reply comes back
- [x] 7.3 Confirm the switcher shows exactly the six allowlisted models and nothing else — revised from the original "no gemini/deepseek/mistral/..." wording, since Mistral and DeepSeek entries are now deliberately present; the check is against `CHAT_MODELS` membership, not provider identity
- [x] 7.4 Confirm an existing/ongoing chat (`chats/show.html.erb`) shows no switcher and keeps using its original model — unchanged, no code in this file touched
- [x] 7.5 Run the full test suite (`bin/rails test`) — 239/239 passing
- [x] 7.6 Confirmed in the browser (real dev server, real login) that the switcher renders correctly and lists all six models with correct labels — also surfaced and fixed the per-process RubyLLM registry cache gotcha (dev server needed a restart after new `Model` rows were created out-of-process)
