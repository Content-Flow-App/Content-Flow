# chat

## Purpose

Chats can be owned by any content record through a polymorphic association, and
each chat is seeded with a layered system prompt built by walking the record's
ancestry chain.

## Requirements

### Requirement: Polymorphic chat ownership
The system SHALL associate a chat with an optional polymorphic owner via `chattable_type` / `chattable_id`. `Chat` SHALL declare `belongs_to :chattable, polymorphic: true, optional: true`. `User`, `Idea`, `Script`, and `LinkedinPost` SHALL each declare `has_many :chats, as: :chattable`. `Creator` SHALL NOT own chats; top-level chats SHALL live on the `User`, and brand context SHALL be reached through `user.creator`.

#### Scenario: A chat is attached to a content record
- **WHEN** a chat is created for an idea, script, or LinkedIn post
- **THEN** the chat's `chattable` resolves to that record

#### Scenario: A standalone chat has no owner
- **WHEN** a chat is created without a chattable
- **THEN** the chat persists with a nil `chattable` and behaves as a plain free-form chat

### Requirement: Cascading LLM context injection
The system SHALL build a layered system prompt by walking the chattable's ancestry chain (`LinkedinPost → Script → Idea → User → Creator`) through `LlmContext.for(chattable)` and SHALL apply it via `chat.with_instructions(...)` when the chat is created. The layering SHALL add the creator profile for an idea chat, the parent idea for a script chat, and the parent idea and parent script (including the script's `system_prompt`) for a LinkedIn post chat.

#### Scenario: Idea chat includes creator context
- **WHEN** a chat is created on an idea
- **THEN** the applied system instructions include the creator's topic, goal, and audience

#### Scenario: Post chat includes full ancestry
- **WHEN** a chat is created on a LinkedIn post
- **THEN** the applied system instructions include the parent idea and the parent script context in addition to the creator profile
