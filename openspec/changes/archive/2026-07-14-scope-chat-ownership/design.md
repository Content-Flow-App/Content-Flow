## Context

`Chat` is polymorphic-only: `belongs_to :chattable, polymorphic: true, optional: true`.
`chattable` was designed to answer "what is this chat about" (it drives
`LlmContext.for(chattable)`'s system-prompt ancestry walk), and the app has
been implicitly reusing that same field to answer "who owns this chat" —
`ChatsController`/`MessagesController` simply never scoped on it at all
(issue #27). The two questions have different answers in one real, reachable
case: a standalone chat (`chattable_id: nil`, created via `new_chat_path` with
no `purpose`/`chattable` params — linked from `models#index`, `models#show`'s
"Start chat with this model", and the Substack feed's "use as inspiration").
That chat has no chattable-chain to walk, so under any scoping scheme built
purely on `chattable`, its own creator would be locked out of it right along
with everyone else.

`Script` and `LinkedinPost`/`TwitterPost`/`InstagramPost` already have this
same "no direct `user_id`" shape, and the existing `authorization` spec
documents the accepted pattern: resolve ownership through the parent chain
(`current_user.ideas`, `current_user_scripts`, `current_user_linkedin_posts`,
etc.) rather than trusting a raw `find`. That pattern doesn't fully close the
gap for `Chat` specifically because, unlike scripts/posts, a chat's parent
chain can be *empty* (standalone chats). Rather than special-case "chattable
present vs. absent" in every controller, this design gives `Chat` a real,
always-populated `user_id` and keeps `chattable` doing only what it always
did — context.

## Goals / Non-Goals

**Goals:**
- Every chat (including standalone ones) has one unambiguous owner, checkable
  with a plain scoped `find` — no OR-chains, no chattable-type branching.
- `chattable`'s existing behavior (context/system-prompt injection via
  `LlmContext`) is completely unchanged.
- Existing tests that rely on `User#chats` meaning "chats where I am the
  chattable" (e.g. `@user.chats.create!(purpose: ...)` in
  `chats_controller_test.rb`) keep passing unmodified.

**Non-Goals:**
- Admin/role-based access (an admin role that bypasses ownership scoping).
  Considered and explicitly deferred — no existing role infrastructure, no
  stated admin use case, and bundling privilege-escalation surface into an
  IDOR fix makes the fix itself harder to review. Left for a future, separate
  proposal if a real need emerges.
- Changing `GenerationsController#set_chat`. It already performs a real
  authorization check via `GenerationPlan`'s `owner_resolver` (scoped through
  `current_user.ideas` / `current_user_scripts` / etc.) before any read or
  enqueue happens. Rewriting it to use `owned_chats` would be a pure style
  change with no security benefit, so it's out of scope here.
- Changing `default_chattable` / which context gets injected into a
  standalone chat. That's a product decision independent of ownership.
- `GeneratedIdeasController` / `GeneratedIdea` — empty scaffold, unrelated.

## Decisions

### 1. Add `chats.user_id` as the sole ownership signal; leave `chattable` untouched

**Alternatives considered:**
- *OR-chain scope mirroring `UserScopedResource`* (e.g. a `current_user_chats`
  method matching chats across every possible `chattable` type). Rejected:
  cannot resolve ownership for a standalone chat at all — chattable_id is
  nil, there's nothing to OR against. Would leave the exact gap that
  motivated this design unfixed for a real, reachable flow.
- *Always default `chattable` to `current_user`* for any chat created without
  an explicit one. Rejected: conflates "who owns this" with "what context to
  inject" — a plain "start chat with this model" would suddenly get the
  creator's brand system-prompt injected, a behavior change nobody asked for.
  It also does nothing for chats that already exist with a nil `chattable_id`.
- *Add `user_id` column* (chosen): orthogonal to `chattable`, resolves every
  existing chat via backfill where a chain exists, and gives standalone chats
  (past and future) a real, direct owner for the first time.

### 2. New `User#owned_chats` association, not a repurposed `User#chats`

`User#chats` (`has_many :chats, as: :chattable`) already has an established
meaning — "chats where the user itself is the chattable subject" — and tests
depend on that meaning (`@user.chats.create!(purpose: "generate_idea")`).
Repurposing it to mean "chats I own" would silently change what those tests
assert against. A distinctly-named association
(`has_many :owned_chats, class_name: "Chat", foreign_key: :user_id`) keeps
both concepts addressable side by side with no ambiguity at the call site.

### 3. Backfill via per-`chattable_type` SQL in the migration, not model callbacks

The backfill needs each post model's existing `parent_idea`/`user` logic
(`script&.idea || idea`), but running it through `ActiveRecord` models inside
a migration couples the migration to model code that can change or be
deleted later. Instead, the migration writes the equivalent joins directly in
SQL (mirroring, not calling, the model methods), so the migration remains
correct and re-runnable regardless of future model changes.

### 4. Standalone chats with no backfillable owner stay `user_id: nil` and become inaccessible

There is no data anywhere (no session log, no audit trail) that says who
created a pre-existing standalone chat. Three options: (a) delete those
rows, (b) guess an owner, (c) leave `user_id` nil and let scoped lookups
naturally 404 them for everyone, including whoever created them. Chosen: (c).
The app is pre-production, so the number of affected rows is expected to be
small-to-zero; guessing (b) would risk assigning someone else's private
conversation to the wrong account, which is worse than the content becoming
unreachable. This is called out explicitly as a **BREAKING** note in the
proposal rather than silently absorbed.

## Risks / Trade-offs

- **[Risk]** Pre-existing standalone chats become permanently inaccessible
  once `user_id` scoping ships, with no way for their creator to get them
  back. → **Mitigation**: acceptable given pre-production status; call it out
  in the proposal so it's a conscious decision, not a surprise. If the number
  of affected rows turns out to be non-trivial before this ships, revisit
  (e.g. query production for a count before deploying).
- **[Risk]** A future `Chat.create!` call (new feature code) forgets to pass
  `user_id`, silently recreating the original gap for that path. →
  **Mitigation**: add a model-level `validates :user_id, presence: true` (or
  equivalent DB `NOT NULL` once legacy nil rows are dealt with) so a missing
  owner fails loudly at save time instead of silently 404ing later.
- **[Risk]** `GenerationsController#set_chat` remains an unscoped `Chat.find`,
  which could look inconsistent to a future reader auditing for this exact
  bug class again. → **Mitigation**: the existing comment above
  `GenerationsController#create` already documents why the real check happens
  via `owner_resolver`; no further mitigation planned, called out explicitly
  as intentionally out of scope so it isn't mistaken for an oversight.

## Migration Plan

1. `add_reference :chats, :user, foreign_key: true, index: true` (nullable).
2. Backfill `user_id` per `chattable_type` via SQL joins (User direct; Idea;
   Script → idea; each post type → parent idea via script-or-idea).
3. Ship `ChatsController#create` stamping `user_id: current_user.id` and the
   scoped-lookup changes to `ChatsController`/`MessagesController` in the same
   deploy as the migration (the scoping change is only safe once `user_id` is
   populated for all currently-reachable chats).
4. No rollback path for the backfill beyond `remove_reference :chats, :user`
   — the migration is additive and non-destructive to existing columns, so
   rollback simply drops the new column with no data loss elsewhere.

## Open Questions

- None outstanding — the standalone-chat data loss trade-off (Decision 4) was
  discussed and accepted during exploration rather than left open.
