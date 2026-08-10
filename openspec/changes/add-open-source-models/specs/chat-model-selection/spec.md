## REMOVED Requirements

### Requirement: Only Anthropic chat models are configured or selectable
**Reason**: Superseded by "Configured chat providers are Anthropic, DeepSeek, and OpenRouter — no others" below. Issue #47 reintroduces open-weight models through dedicated, individually-verified credentials (DeepSeek native provider; Kimi K3 / GLM-5.2 via OpenRouter) rather than through a shared aggregator like GitHub Models, so the Anthropic-only restriction no longer holds.
**Migration**: No user-facing migration — existing Anthropic-only chats are unaffected. See the new requirement for the current provider boundary.

## ADDED Requirements

### Requirement: Configured chat providers are Anthropic, DeepSeek, and OpenRouter — no others
The system SHALL NOT configure or expose any chat provider other than Anthropic direct, DeepSeek direct, and OpenRouter. GitHub Models (`models.github.ai/inference`) and any model reachable only through it SHALL NOT be configured in `config/initializers/ruby_llm.rb` and SHALL NOT appear in `ApplicationController::CHAT_MODELS`.

#### Scenario: No GitHub-Models-routed provider is configured
- **WHEN** the RubyLLM initializer runs
- **THEN** no GitHub Models credential (`openai_api_key` pointed at `models.github.ai`) is read

#### Scenario: Previously-selectable GitHub-Models-routed models are gone
- **WHEN** a user opens the new-chat form
- **THEN** the model switcher does not list `gpt-4o`, `gpt-4o-mini`, `gpt-4.1`, `mistral-ai/mistral-small-2503`, or `deepseek/deepseek-v3-0324` (the GitHub-Models-routed DeepSeek id — distinct from the DeepSeek-native id now reachable directly)

#### Scenario: Only Anthropic, DeepSeek, and OpenRouter models are ever presented
- **WHEN** a user opens the new-chat form
- **THEN** every model listed in the switcher belongs to the `anthropic`, `deepseek`, or `openrouter` RubyLLM provider

### Requirement: OpenRouter-routed models display their real publisher
OpenRouter fronts multiple publishers (e.g. Moonshot AI, Zhipu) under RubyLLM's single `openrouter` provider tag. The system SHALL display each OpenRouter-routed model's true publisher, not the literal string "OpenRouter", everywhere a model's provider is shown to a user (the new-chat switcher and the `/models` registry pages), the same way GitHub-Models-routed models previously displayed their real publisher via `metadata[:real_publisher]`.

#### Scenario: Kimi displays as Moonshot AI, not OpenRouter
- **WHEN** a user views the model switcher or the `/models` registry page
- **THEN** an OpenRouter-routed Kimi model displays its Moonshot AI publisher name, not "OpenRouter"

#### Scenario: GLM displays as Zhipu, not OpenRouter
- **WHEN** a user views the model switcher or the `/models` registry page
- **THEN** an OpenRouter-routed GLM model displays its Zhipu publisher name, not "OpenRouter"

#### Scenario: Native Anthropic and DeepSeek models are unaffected
- **WHEN** a user views the model switcher or the `/models` registry page
- **THEN** Anthropic and DeepSeek-native models display their normal RubyLLM provider name ("Anthropic" / "Deepseek") exactly as before

## MODIFIED Requirements

### Requirement: New-chat model switcher scoped to an exact, individually-verified model allowlist
The system SHALL present a model switcher on new-chat creation listing only models present in an exact `[provider, model_id]` allowlist (`ApplicationController::CHAT_MODELS`), not merely models whose provider is configured. A provider-level allowlist is insufficient: RubyLLM's registry tags some non-chat models (e.g. `dall-e-3`, `whisper-1`, `tts-1`, `sora-2`) as `type: "chat"` regardless of provider — a provider check alone cannot exclude them. As of this change the allowlist SHALL be exactly `anthropic/claude-opus-5`, `anthropic/claude-sonnet-5`, `anthropic/claude-haiku-4-5-20251001`, DeepSeek's native chat model (provider `deepseek`), and OpenRouter entries for Kimi K3 and/or GLM-5.2 (provider `openrouter`) — each confirmed live against its provider's own model-listing API (DeepSeek's `v1/models`, OpenRouter's `/api/v1/models`) before being added, exactly as the three Anthropic entries were.

#### Scenario: Switcher excludes non-chat models under an otherwise-allowed provider
- **WHEN** a user opens the new-chat form
- **THEN** the model switcher does not list `dall-e-3`, `whisper-1`, `tts-1`, `sora-2`, or any other non-chat model, even though they may share a provider with allowlisted models

#### Scenario: Selecting a listed model never raises a configuration error
- **WHEN** a user selects any model presented by the switcher and starts a chat
- **THEN** the chat is created successfully without raising `RubyLLM::ConfigurationError`

#### Scenario: Claude Opus 5 and Claude Haiku 4.5 are selectable
- **WHEN** a user creates a new chat and selects Claude Opus 5 or Claude Haiku 4.5
- **THEN** the chat's model resolves to `claude-opus-5` or `claude-haiku-4-5-20251001` (provider `anthropic`) respectively, and generation proceeds normally

#### Scenario: DeepSeek is selectable and generates a real reply
- **WHEN** a user creates a new chat and selects the DeepSeek model
- **THEN** the chat's model resolves to DeepSeek's native provider and generation proceeds normally

#### Scenario: An OpenRouter-routed model is selectable and generates a real reply
- **WHEN** a user creates a new chat and selects Kimi K3 or GLM-5.2 from the switcher
- **THEN** the chat's model resolves to the corresponding `openrouter` provider entry and generation proceeds normally
