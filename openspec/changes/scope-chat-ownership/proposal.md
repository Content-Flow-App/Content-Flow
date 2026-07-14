## Why

`ChatsController#set_chat` and `MessagesController#set_chat` resolve a chat by
raw id with no ownership check, and `ChatsController#index` lists every chat
in the system with no scoping at all. Any signed-in user can view, delete, or
post into (triggering a real, billed LLM call on) any other user's chat by
guessing or incrementing an id (GitHub issue #27). The gap exists because
`Chat` has no `user_id` — ownership can only be inferred indirectly through
its polymorphic `chattable`, and that chain breaks down entirely for
standalone/free-form chats (`chattable_id: nil`), which are a real, reachable
flow in the app today. Closing the hole requires giving every chat a direct,
unambiguous owner, then scoping every chat/message lookup through it.

## What Changes

- Add a `user_id` column to `chats`, backfilled from the existing `chattable`
  ancestry chain (`User` direct, `Idea`, `Script` → idea, and each post type's
  `parent_idea` → idea), decoupled from `chattable` — `chattable` keeps doing
  exactly what it does today (driving `LlmContext` system-prompt injection);
  `user_id` is the sole source of truth for ownership/authorization.
- `ChatsController#create` stamps `user_id: current_user.id` on every chat it
  creates, regardless of what `chattable` resolves to (including standalone
  chats, which today have no ownership signal at all).
- Add `User#owned_chats` (`has_many :chats, class_name: "Chat", foreign_key: :user_id`)
  as a new, distinctly-named association — `User#chats` already exists and
  means something different (chats where the user itself is the `chattable`
  subject); it is unchanged.
- Scope `ChatsController#set_chat` (`show`/`destroy`), `ChatsController#index`,
  and `MessagesController#set_chat` (`create`) through `current_user.owned_chats`
  instead of unscoped `Chat.find` / `Chat.order`.
- Add regression tests: a non-owner gets 404 on `GET`/`DELETE` a chat and on
  `POST` a message into it; `index` never returns another user's chats; a
  standalone chat remains visible to its own creator after the fix.
- **BREAKING**: `chats.user_id` is a new NOT-NULL-in-practice invariant for all
  chats created going forward. Pre-existing standalone chats
  (`chattable_id: nil`) cannot be backfilled — there is no signal for who
  created them. This proposal treats that as acceptable (see design.md for
  the reasoning) since the app is pre-production; those rows are left with a
  nil `user_id` and become permanently inaccessible through the app rather
  than migrated to a guessed owner.

## Capabilities

### New Capabilities
_None._

### Modified Capabilities
- `chat`: adds a direct-ownership requirement — every chat has a `user_id`
  set at creation, independent of and in addition to its polymorphic
  `chattable`. The existing "Polymorphic chat ownership" and "Cascading LLM
  context injection" requirements are unchanged; `chattable` continues to
  govern context only, not access control.
- `authorization`: extends the existing user-scoped-lookup pattern (already
  applied to scripts and LinkedIn posts, which also carry no direct
  `user_id`) to chats and messages, now that chats have a real `user_id` to
  scope through.

## Impact

- **Schema**: new migration adding `chats.user_id` (FK + index) and a data
  backfill.
- **Models**: `Chat` (`belongs_to :user`), `User` (`has_many :owned_chats`).
- **Controllers**: `ChatsController` (`set_chat`, `index`, `create`),
  `MessagesController` (`set_chat`).
- **Not touched**: `GenerationsController#set_chat` (already protected by
  `GenerationPlan`'s owner-resolver check before any side effect), the
  `default_chattable`/`chattable` context-selection logic, and
  `GeneratedIdeasController`/`GeneratedIdea` (unrelated dead scaffold code).
- **Tests**: `test/controllers/chats_controller_test.rb`,
  `test/controllers/messages_controller_test.rb`, migration/model tests for
  the new `user_id` backfill and association.
