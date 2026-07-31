# chat-model-selection

## Purpose

New chats default to Claude Sonnet 5 while still allowing an explicit,
individually-verified allowlist of Anthropic models to be chosen at creation
time. GitHub Models — the prior route to OpenAI/Mistral/DeepSeek chat models —
was dropped entirely (issue #45): GitHub confirmed, via a live API error,
that it is mid "scheduled retirement brownout" (`RubyLLM::Error: GitHub
Models is temporarily unavailable as part of a scheduled retirement
brownout.`). That is not a transient outage but GitHub sunsetting the free
inference endpoint, so any chat routed through it — including chats created
before Anthropic became the default — was liable to break in production with
no recovery. Anthropic direct is now the only supported chat provider. The
switcher only lists models that have been individually confirmed to work,
since RubyLLM's registry cannot be trusted to expose only usable chat models
via provider configuration alone. Model selection is fixed once a chat is
created.

## Requirements

### Requirement: Default model is Claude Sonnet 5
The system SHALL use `claude-sonnet-5` (provider `anthropic`) as `RubyLLM.config.default_model`. A new chat created with no explicit model selection SHALL resolve to this model.

#### Scenario: New chat with no model chosen defaults to Claude Sonnet 5
- **WHEN** a user creates a new chat without selecting a model
- **THEN** the chat's model resolves to `claude-sonnet-5` on the `anthropic` provider

### Requirement: Only Anthropic chat models are configured or selectable
The system SHALL NOT configure or expose any chat provider other than Anthropic direct. GitHub Models (`models.github.ai/inference`) and any model reachable only through it SHALL NOT be configured in `config/initializers/ruby_llm.rb` and SHALL NOT appear in `ApplicationController::CHAT_MODELS`.

#### Scenario: No OpenAI-compatible provider is configured
- **WHEN** the RubyLLM initializer runs
- **THEN** no `openai_api_key` or `openai_api_base` is set, and no GitHub Models credential is read

#### Scenario: Previously-selectable GitHub-Models-routed models are gone
- **WHEN** a user opens the new-chat form
- **THEN** the model switcher does not list `gpt-4o`, `gpt-4o-mini`, `gpt-4.1`, `mistral-ai/mistral-small-2503`, or `deepseek/deepseek-v3-0324`

### Requirement: New-chat model switcher scoped to an exact, individually-verified model allowlist
The system SHALL present a model switcher on new-chat creation listing only models present in an exact `[provider, model_id]` allowlist (`ApplicationController::CHAT_MODELS`), not merely models whose provider is configured. A provider-level allowlist is insufficient: RubyLLM's registry tags some non-chat models (e.g. `dall-e-3`, `whisper-1`, `tts-1`, `sora-2`) as `type: "chat"` regardless of provider — a provider check alone cannot exclude them. As of this change the allowlist SHALL be exactly `anthropic/claude-opus-5`, `anthropic/claude-sonnet-5`, and `anthropic/claude-haiku-4-5-20251001`, each confirmed live against Anthropic's `v1/models` before being added.

#### Scenario: Switcher excludes non-chat models under an otherwise-allowed provider
- **WHEN** a user opens the new-chat form
- **THEN** the model switcher does not list `dall-e-3`, `whisper-1`, `tts-1`, `sora-2`, or any other non-chat model, even though they may share a provider with allowlisted models

#### Scenario: Selecting a listed model never raises a configuration error
- **WHEN** a user selects any model presented by the switcher and starts a chat
- **THEN** the chat is created successfully without raising `RubyLLM::ConfigurationError`

#### Scenario: Claude Opus 5 and Claude Haiku 4.5 are selectable
- **WHEN** a user creates a new chat and selects Claude Opus 5 or Claude Haiku 4.5
- **THEN** the chat's model resolves to `claude-opus-5` or `claude-haiku-4-5-20251001` (provider `anthropic`) respectively, and generation proceeds normally

### Requirement: Model selection is fixed at chat creation
The system SHALL determine a chat's model only at creation time. Switching the model of an already-started chat SHALL NOT be supported by this capability.

#### Scenario: An existing chat's model does not change
- **WHEN** a user continues a conversation on an already-created chat
- **THEN** the chat keeps using the model it was created with, with no switcher or model-change control presented on that page
