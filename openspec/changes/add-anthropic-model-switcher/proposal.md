## Why

The app has run on a single working LLM path since inception: GitHub Models' OpenAI-compatible endpoint (`gpt-4o-mini`, paid for by a GitHub token, not billed). Anthropic support has existed only as an unused config stub. A real Anthropic Console API key is now live on Heroku, and Claude Sonnet 5 should become the new default model — but the GitHub Models path must keep working so existing behavior and cost characteristics aren't silently lost. Today the only way to pick a model at all is a `<select>` that already exists in the new-chat form markup but is hidden (`class="... hidden"`) and unscoped — it lists every provider RubyLLM knows about (~1350 models across gemini, deepseek, mistral, perplexity, xai, azure, bedrock, vertexai, openrouter, ollama, gpustack, in addition to openai and anthropic), almost none of which are configured, so unhiding it as-is would let a user pick a model that immediately raises `RubyLLM::ConfigurationError`.

## What Changes

- Set `RubyLLM.config.default_model` to `claude-sonnet-5` (anthropic provider). **BREAKING**: new chats with no explicit model selection now default to a different provider and model than before.
- Keep `gpt-4o-mini` (openai / GitHub Models) fully configured and selectable — it is no longer the default but remains a first-class option.
- Refresh the app's `models` registry (`Model.refresh!`) so `claude-sonnet-5` exists as a real row (pricing, context window, capabilities) rather than only resolving via `assume_model_exists`.
- Scope `available_chat_models` (`app/controllers/application_controller.rb`) to only the `openai` and `anthropic` providers, so the switcher can never present a model that will fail with a configuration error.
- Un-hide and style the existing model `<select>` in `app/views/chats/_form.html.erb` per `DESIGN.md` conventions, so a user can choose the model when starting a **new** chat.
- Out of scope: switching a model on an already-started chat (`chats/show.html.erb` is unchanged), and surfacing per-chat/per-message cost (`chat.cost` stays unused).

## Capabilities

### New Capabilities
- `chat-model-selection`: Lets a user choose which configured LLM model (openai or anthropic) powers a new chat at creation time, defaulting to Claude Sonnet 5 when no explicit choice is made.

### Modified Capabilities
(none — `chat`, `chat-generation`, and `chat-refinement` specs describe chat ownership, context injection, and generation/refinement flows; none of their existing requirements reference model selection, so this is additive only)

## Impact

- **Config**: `config/initializers/ruby_llm.rb` — `default_model` changes; the existing GitHub-Models-specific payload patch (prefixes outgoing model id with `openai/` only when `openai_api_base` points at `models.github.ai`) is unrelated and untouched.
- **Data**: `models` table gains a `claude-sonnet-5` / `anthropic` row via `Model.refresh!` against the now-live Anthropic API.
- **Code**: `app/controllers/application_controller.rb` (`available_chat_models` scoping), `app/views/chats/_form.html.erb` (un-hide + style the select), `app/controllers/chats_controller.rb` (`#new`/`#create` already thread `model` through — verify still correct once scoped).
- **Cost**: Anthropic's Console API is metered/billed, unlike the free GitHub Models path — this is the first time the app defaults to a paid provider.
- **No changes** to `chats/show.html.erb`, `ChatResponseJob`, `GenerationJob`, or `StructuredExtraction` — they already resolve the model generically through the chat's persisted association.
