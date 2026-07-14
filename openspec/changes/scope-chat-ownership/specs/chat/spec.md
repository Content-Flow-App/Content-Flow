## ADDED Requirements

### Requirement: Direct chat ownership
The system SHALL record a direct, non-polymorphic owner for every chat via
`chats.user_id`, set at creation time regardless of what the chat's
`chattable` resolves to (including a chat with no `chattable` at all).
`Chat` SHALL declare `belongs_to :user`. `User` SHALL declare
`has_many :owned_chats, class_name: "Chat", foreign_key: :user_id` as a
separate association from the existing `User#chats` (which continues to mean
"chats where this user is the `chattable` subject", per the Polymorphic chat
ownership requirement, and is unchanged by this requirement). `user_id` SHALL
be the sole basis for authorization; `chattable` SHALL continue to serve only
as the input to LLM context injection and SHALL NOT be used to determine
access.

#### Scenario: A chat created with a chattable is also directly owned
- **WHEN** a chat is created for an idea, script, or LinkedIn post owned by
  the current user
- **THEN** the chat's `user_id` is set to the current user's id, in addition
  to its `chattable` being set to that record

#### Scenario: A standalone chat is directly owned
- **WHEN** a chat is created with no `chattable` (a plain free-form chat)
- **THEN** the chat's `user_id` is still set to the current user's id, so its
  creator can retrieve it later
