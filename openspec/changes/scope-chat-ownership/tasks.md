## 1. Migration and backfill

- [x] 1.1 Generate migration adding `user_id` to `chats` (`add_reference :chats, :user, foreign_key: true, index: true`, nullable)
- [x] 1.2 In the same migration, backfill `user_id` via SQL joins per `chattable_type`: `User` direct, `Idea`, `Script` → idea, and each of `LinkedinPost`/`TwitterPost`/`InstagramPost` → parent idea via script-or-idea
- [x] 1.3 Run the migration against a copy of current data (or dev db) and confirm the count of rows left with `user_id: nil` is limited to standalone chats (`chattable_id: nil`) — no unexpected misses on rows that do have a chattable

## 2. Models

- [x] 2.1 Add `belongs_to :user` to `Chat` (leave `belongs_to :chattable` untouched)
- [x] 2.2 Add `validates :user_id, presence: true` on `Chat` so any future creation path that forgets to stamp an owner fails loudly at save time
- [x] 2.3 Add `has_many :owned_chats, class_name: "Chat", foreign_key: :user_id` to `User` (do not modify the existing `has_many :chats, as: :chattable`)

## 3. Controllers

- [ ] 3.1 `ChatsController#create`: stamp `user_id: current_user.id` on every created chat, regardless of `chattable`
- [ ] 3.2 `ChatsController#set_chat`: change to `current_user.owned_chats.find(params[:id])`
- [ ] 3.3 `ChatsController#index`: change to `current_user.owned_chats.order(created_at: :desc)`
- [ ] 3.4 `MessagesController#set_chat`: change to `current_user.owned_chats.find(params[:chat_id])`

## 4. Tests

- [ ] 4.1 `chats_controller_test.rb`: non-owner gets 404 on `GET show` for another user's chat
- [ ] 4.2 `chats_controller_test.rb`: non-owner gets 404 on `DELETE destroy` for another user's chat, and the chat is not destroyed
- [ ] 4.3 `chats_controller_test.rb`: `index` only returns the current user's own chats, never another user's (create chats for two users, assert the response excludes the other user's)
- [ ] 4.4 `chats_controller_test.rb`: a standalone chat (created with no `chattable`) is owned by and visible to its creator (regression guard for the gap that motivated `user_id`)
- [ ] 4.5 `messages_controller_test.rb`: non-owner gets 404 on `POST create` into another user's chat, no message is persisted, and no `ChatResponseJob` is enqueued
- [ ] 4.6 Model test: `Chat` backfill/association — creating a chat without `user_id` is invalid; `User#owned_chats` returns chats by `user_id` and is distinct from `User#chats`

## 5. Verification

- [ ] 5.1 Run the full test suite and confirm no existing test relying on `User#chats` (chattable-based) regresses
- [ ] 5.2 Manually verify in `bin/dev`: sign in as two different users, confirm user A cannot open, delete, or message into user B's chat by editing the URL, and that `/chats` for each user shows only their own
