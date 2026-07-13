## ADDED Requirements

### Requirement: Default model is Claude Sonnet 5
The system SHALL use `claude-sonnet-5` (provider `anthropic`) as `RubyLLM.config.default_model`. A new chat created with no explicit model selection SHALL resolve to this model.

#### Scenario: New chat with no model chosen defaults to Claude Sonnet 5
- **WHEN** a user creates a new chat without selecting a model
- **THEN** the chat's model resolves to `claude-sonnet-5` on the `anthropic` provider

### Requirement: The prior default remains selectable
The system SHALL keep `gpt-4o-mini` (provider `openai`, routed through GitHub Models) fully configured and available for explicit selection, even though it is no longer the default.

#### Scenario: User explicitly picks the previous default
- **WHEN** a user creates a new chat and selects `gpt-4o-mini` from the model switcher
- **THEN** the chat's model resolves to `gpt-4o-mini` on the `openai` provider and generation proceeds normally

### Requirement: New-chat model switcher scoped to an exact, individually-verified model allowlist
The system SHALL present a model switcher on new-chat creation listing only models present in an exact `[provider, model_id]` allowlist (`ApplicationController::CHAT_MODELS`), not merely models whose provider is configured. A provider-level allowlist is insufficient: RubyLLM's registry tags some non-chat models (e.g. `dall-e-3`, `whisper-1`, `tts-1`, `sora-2`) as `type: "chat"` regardless of provider, and some models exist under multiple providers with the identical bare id (e.g. `gpt-4o-mini` under both `openai` and the unconfigured `azure`) — a provider check alone cannot exclude either case.

#### Scenario: Switcher excludes non-chat models under an otherwise-allowed provider
- **WHEN** a user opens the new-chat form
- **THEN** the model switcher does not list `dall-e-3`, `whisper-1`, `tts-1`, `sora-2`, or any other non-chat model, even though they share a provider with allowlisted models

#### Scenario: Switcher excludes a same-named model under an unconfigured provider
- **WHEN** a user opens the new-chat form
- **THEN** the model switcher does not list the `azure` copy of `gpt-4o` or `gpt-4o-mini`, only the `openai` ones

#### Scenario: Selecting a listed model never raises a configuration error
- **WHEN** a user selects any model presented by the switcher and starts a chat
- **THEN** the chat is created successfully without raising `RubyLLM::ConfigurationError`

### Requirement: GitHub Models' multi-vendor catalog is available, not just OpenAI
The system SHALL treat GitHub Models as a multi-vendor aggregator and make individually-verified non-OpenAI models available through it, in addition to Anthropic direct and OpenAI-via-GitHub-Models. As of this change the allowlist SHALL include `openai/gpt-4o`, `openai/gpt-4o-mini`, `openai/gpt-4.1`, `mistral-ai/mistral-small-2503` (Mistral), and `deepseek/deepseek-v3-0324` (DeepSeek), alongside `anthropic/claude-sonnet-5`. Models the GitHub Models catalog lists but that return an error for the configured token (as of this change: the GPT-5 family and the o1/o3/o4 reasoning tier, both confirmed via live request to return `400`/`403`) SHALL NOT be added merely because they appear in the catalog.

#### Scenario: A Mistral model is selectable and generates a real reply
- **WHEN** a user creates a new chat and selects Mistral Small 3.1
- **THEN** the chat's model resolves to `mistral-ai/mistral-small-2503` and generation proceeds normally

#### Scenario: A DeepSeek model is selectable and generates a real reply
- **WHEN** a user creates a new chat and selects DeepSeek-V3-0324
- **THEN** the chat's model resolves to `deepseek/deepseek-v3-0324` and generation proceeds normally

### Requirement: Non-OpenAI models routed through GitHub Models display their real publisher
The system SHALL display the true publisher of a model, not the RubyLLM provider it happens to be registered under for credential-routing purposes. Models registered under the `openai` provider whose registry `metadata` carries a `real_publisher` key SHALL display that publisher's name instead of "OpenAI", everywhere a model's provider is shown to a user (the new-chat switcher and the `/models` registry pages). Models without a `real_publisher` in their metadata SHALL continue to display RubyLLM's own provider name unchanged.

#### Scenario: Mistral model displays as Mistral, not OpenAI
- **WHEN** a user views the model switcher or the `/models` registry page
- **THEN** `mistral-ai/mistral-small-2503` displays as "Mistral - Mistral Small 3.1", not "OpenAI - Mistral Small 3.1"

#### Scenario: DeepSeek model displays as DeepSeek, not OpenAI
- **WHEN** a user views the model switcher or the `/models` registry page
- **THEN** `deepseek/deepseek-v3-0324` displays as "DeepSeek - DeepSeek-V3-0324", not "OpenAI - DeepSeek-V3-0324"

#### Scenario: Native OpenAI and Anthropic models are unaffected
- **WHEN** a user views the model switcher or the `/models` registry page
- **THEN** `gpt-4o`, `gpt-4o-mini`, `gpt-4.1`, and `claude-sonnet-5` display their normal RubyLLM provider name ("OpenAI" / "Anthropic") exactly as before

### Requirement: Model selection is fixed at chat creation
The system SHALL determine a chat's model only at creation time. Switching the model of an already-started chat SHALL NOT be supported by this capability.

#### Scenario: An existing chat's model does not change
- **WHEN** a user continues a conversation on an already-created chat
- **THEN** the chat keeps using the model it was created with, with no switcher or model-change control presented on that page
