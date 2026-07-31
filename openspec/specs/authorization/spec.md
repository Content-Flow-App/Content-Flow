# authorization

## Purpose

Scripts and LinkedIn posts carry no `user_id`, so access control runs through
ownership of the parent idea. Requests for records the user does not own are
blocked.

## Requirements

### Requirement: Cross-user authorization for content records
The system SHALL authorize access to scripts and LinkedIn posts through ownership rather than direct lookup, since these records carry no `user_id`. Scripts SHALL be resolved through `idea.user`. LinkedIn posts SHALL be resolved through `current_user_linkedin_posts`, which SHALL cover **both** parent paths — a post owned via its script's idea **or** via its directly-attached idea — by left-joining both associations and matching either idea's `user_id` to the current user. A request for a record the user does not own SHALL be blocked.

#### Scenario: Owner accesses their script
- **WHEN** a user requests one of their own scripts
- **THEN** the system resolves it through `current_user` ownership and renders it

#### Scenario: Non-owner is blocked from a script
- **WHEN** user B requests user A's `script_path`
- **THEN** the user-scoped lookup fails and access is blocked

#### Scenario: Owner accesses a directly-created post
- **WHEN** a user requests a LinkedIn post they created directly from their own idea
- **THEN** `current_user_linkedin_posts` resolves it through the idea path and access is allowed

#### Scenario: Non-owner is blocked from a LinkedIn post
- **WHEN** user B requests user A's LinkedIn post by either the script-nested or idea-nested path
- **THEN** the user-scoped lookup fails and access is blocked

### Requirement: Cross-user authorization for chats and messages
The system SHALL authorize access to chats, and to posting messages into a chat, through the chat's direct `user_id` owner rather than an unscoped lookup by id. `ChatsController#show`, `ChatsController#destroy`, and `MessagesController#create` SHALL resolve their chat through `current_user.owned_chats.find(...)`. `ChatsController#index` SHALL list only `current_user.owned_chats`, never every chat in the system. A request for a chat the current user does not own SHALL be blocked with a not-found response, matching the existing scoped-`find` pattern used for scripts and LinkedIn posts.

#### Scenario: Owner views their own chat
- **WHEN** a user requests `GET` on their own `chat_path`
- **THEN** the system resolves it through `current_user.owned_chats` and renders it

#### Scenario: Non-owner is blocked from viewing a chat
- **WHEN** user B requests user A's `chat_path` by id
- **THEN** the scoped lookup fails with `ActiveRecord::RecordNotFound` and the response is not found

#### Scenario: Non-owner is blocked from destroying a chat
- **WHEN** user B sends `DELETE` to user A's `chat_path` by id
- **THEN** the scoped lookup fails, the chat is not destroyed, and the response is not found

#### Scenario: Non-owner is blocked from posting a message into a chat
- **WHEN** user B sends `POST` to user A's `chat_messages_path` by id
- **THEN** the scoped lookup fails, no message is persisted, no `ChatResponseJob` is enqueued, and the response is not found

#### Scenario: Chat index only shows the current user's chats
- **WHEN** a user requests `GET /chats`
- **THEN** the response includes only chats owned by the current user and excludes every other user's chats

### Requirement: Email format validation
The system SHALL validate email addresses using a regex that enforces: word
characters, `+`, `-`, and `.` in the local part; an alphanumeric domain with
optional hyphens; at least one dot separating domain labels; and a TLD of one or
more alpha characters. The regex SHALL be case-insensitive. Addresses without a
TLD (e.g. `user@localhost`) SHALL be rejected.

#### Scenario: Valid email is accepted
- **WHEN** a user registers with `creator@example.com`
- **THEN** the system accepts the email format

#### Scenario: Email without TLD is rejected
- **WHEN** a user registers with `creator@localhost`
- **THEN** the system rejects the email with a format error

#### Scenario: Email with subdomain is accepted
- **WHEN** a user registers with `creator@mail.example.co.uk`
- **THEN** the system accepts the email format

#### Scenario: Email with special local-part characters is accepted
- **WHEN** a user registers with `first+tag@example.com`
- **THEN** the system accepts the email format

### Requirement: Password strength
The system SHALL require passwords to be between 15 and 128 characters, contain
at least one numeric digit, and contain at least one symbol (any character that
is not a letter, digit, or whitespace). These rules SHALL apply only when a
password is being set or changed — existing users are not forced to update on
sign-in.

#### Scenario: Strong password is accepted
- **WHEN** a user sets their password to `MyStr0ngP@ssword!`
- **THEN** the system accepts the password

#### Scenario: Password too short is rejected
- **WHEN** a user sets their password to `Short1!`
- **THEN** the system rejects the password with a minimum-length error

#### Scenario: Password without a number is rejected
- **WHEN** a user sets their password to `NoNumbersHere!!!`
- **THEN** the system rejects the password with a "must include a number" error

#### Scenario: Password without a symbol is rejected
- **WHEN** a user sets their password to `NoSymbolsHere123`
- **THEN** the system rejects the password with a "must include a symbol" error

#### Scenario: Existing user signs in with old weak password
- **WHEN** a user who set a 6-character password before the policy change signs in
- **THEN** the system allows sign-in because validation runs on set/change only
