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

- [ ] 3.1 Add a `CHAT_PROVIDERS = %w[openai anthropic].freeze` constant to `app/controllers/application_controller.rb`
- [ ] 3.2 Update `available_chat_models` to filter `RubyLLM.models.chat_models.all` to `CHAT_PROVIDERS` before sorting
- [ ] 3.3 Verify `ModelsController#index` (which also calls `available_chat_models`) still renders correctly with the narrowed list

## 4. New-chat switcher UI

- [ ] 4.1 Remove `hidden` from the wrapping `div` around the model `<select>` in `app/views/chats/_form.html.erb`
- [ ] 4.2 Style the label/select per `DESIGN.md` (cf-label conventions, no shadows, matches the rest of the composer)
- [ ] 4.3 Confirm `chats_controller.rb#new` (`@selected_model`, `@chat_models`) and `#create` (`model: params.dig(:chat, :model).presence`) still work unchanged against the scoped list
- [ ] 4.4 Confirm `default_model_display_name` (used as the select's "use default" option label) reflects Claude Sonnet 5

## 5. Verification

- [ ] 5.1 Start a new chat with no model selected — confirm it resolves to `claude-sonnet-5` / `anthropic` and a real reply comes back
- [ ] 5.2 Start a new chat explicitly selecting `gpt-4o-mini` — confirm it still resolves to `openai` / GitHub Models and a real reply comes back
- [ ] 5.3 Confirm the switcher shows only openai and anthropic models — no gemini/deepseek/mistral/perplexity/xai/azure/bedrock/vertexai/openrouter/ollama/gpustack entries
- [ ] 5.4 Confirm an existing/ongoing chat (`chats/show.html.erb`) shows no switcher and keeps using its original model
- [ ] 5.5 Run the full test suite (`bin/rails test`)
