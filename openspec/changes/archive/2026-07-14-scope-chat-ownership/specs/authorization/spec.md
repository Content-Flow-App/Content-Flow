## ADDED Requirements

### Requirement: Cross-user authorization for chats and messages
The system SHALL authorize access to chats, and to posting messages into a
chat, through the chat's direct `user_id` owner rather than an unscoped
lookup by id. `ChatsController#show`, `ChatsController#destroy`, and
`MessagesController#create` SHALL resolve their chat through
`current_user.owned_chats.find(...)`. `ChatsController#index` SHALL list only
`current_user.owned_chats`, never every chat in the system. A request for a
chat the current user does not own SHALL be blocked with a not-found
response, matching the existing scoped-`find` pattern used for scripts and
LinkedIn posts.

#### Scenario: Owner views their own chat
- **WHEN** a user requests `GET` on their own `chat_path`
- **THEN** the system resolves it through `current_user.owned_chats` and
  renders it

#### Scenario: Non-owner is blocked from viewing a chat
- **WHEN** user B requests user A's `chat_path` by id
- **THEN** the scoped lookup fails with `ActiveRecord::RecordNotFound` and the
  response is not found

#### Scenario: Non-owner is blocked from destroying a chat
- **WHEN** user B sends `DELETE` to user A's `chat_path` by id
- **THEN** the scoped lookup fails, the chat is not destroyed, and the
  response is not found

#### Scenario: Non-owner is blocked from posting a message into a chat
- **WHEN** user B sends `POST` to user A's `chat_messages_path` by id
- **THEN** the scoped lookup fails, no message is persisted, no
  `ChatResponseJob` is enqueued, and the response is not found

#### Scenario: Chat index only shows the current user's chats
- **WHEN** a user requests `GET /chats`
- **THEN** the response includes only chats owned by the current user and
  excludes every other user's chats
