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
The system SHALL build a layered system prompt by walking the chattable's ancestry chain (`LinkedinPost → Script → Idea → User → Creator`) through `LlmContext.for(chattable)` and SHALL apply it via `chat.with_instructions(...)` when the chat is created. The layering SHALL add the creator profile for an idea chat, the parent idea for a script chat, and the parent idea and parent script (including the script's `system_prompt`) for a LinkedIn post chat. For a LinkedIn post the parent idea SHALL be resolved as `script&.idea || idea`, and the script layer SHALL be skipped (nil-safe) when the post belongs directly to an idea with no script.

#### Scenario: Idea chat includes creator context
- **WHEN** a chat is created on an idea
- **THEN** the applied system instructions include the creator's topic, goal, and audience

#### Scenario: Post chat includes full ancestry
- **WHEN** a chat is created on a LinkedIn post that belongs to a script
- **THEN** the applied system instructions include the parent idea and the parent script context in addition to the creator profile

#### Scenario: Directly-created post chat skips the script layer
- **WHEN** a chat is created on a LinkedIn post that belongs directly to an idea with no script
- **THEN** the applied system instructions include the parent idea and the creator profile but no script layer

### Requirement: Direct chat ownership
The system SHALL record a direct, non-polymorphic owner for every chat via `chats.user_id`, set at creation time regardless of what the chat's `chattable` resolves to (including a chat with no `chattable` at all). `Chat` SHALL declare `belongs_to :user`. `User` SHALL declare `has_many :owned_chats, class_name: "Chat", foreign_key: :user_id` as a separate association from the existing `User#chats` (which continues to mean "chats where this user is the `chattable` subject", per the Polymorphic chat ownership requirement, and is unchanged by this requirement). `user_id` SHALL be the sole basis for authorization; `chattable` SHALL continue to serve only as the input to LLM context injection and SHALL NOT be used to determine access.

#### Scenario: A chat created with a chattable is also directly owned
- **WHEN** a chat is created for an idea, script, or LinkedIn post owned by the current user
- **THEN** the chat's `user_id` is set to the current user's id, in addition to its `chattable` being set to that record

#### Scenario: A standalone chat is directly owned
- **WHEN** a chat is created with no `chattable` (a plain free-form chat)
- **THEN** the chat's `user_id` is still set to the current user's id, so its creator can retrieve it later
