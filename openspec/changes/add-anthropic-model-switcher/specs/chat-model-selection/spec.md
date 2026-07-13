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

### Requirement: New-chat model switcher scoped to configured providers
The system SHALL present a model switcher on new-chat creation listing only models whose provider is `openai` or `anthropic`. Models from any other provider RubyLLM's registry knows about (including but not limited to gemini, deepseek, mistral, perplexity, xai, azure, bedrock, vertexai, openrouter, ollama, gpustack) SHALL NOT appear as selectable options, since those providers are not configured with working credentials.

#### Scenario: Switcher excludes unconfigured providers
- **WHEN** a user opens the new-chat form
- **THEN** the model switcher lists only `openai` and `anthropic` models and no others

#### Scenario: Selecting a listed model never raises a configuration error
- **WHEN** a user selects any model presented by the switcher and starts a chat
- **THEN** the chat is created successfully without raising `RubyLLM::ConfigurationError`

### Requirement: Model selection is fixed at chat creation
The system SHALL determine a chat's model only at creation time. Switching the model of an already-started chat SHALL NOT be supported by this capability.

#### Scenario: An existing chat's model does not change
- **WHEN** a user continues a conversation on an already-created chat
- **THEN** the chat keeps using the model it was created with, with no switcher or model-change control presented on that page
