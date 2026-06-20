## Issue set

All issues: repo `theodora22/Content-Flow`, assignee `theodora22`, project #4 "Project - Content Flow", **Status = Backlog**. Sequencing: A1→A2→A3 → B1 → C1 → D1 → E1 → (F1→F2→F3→F4) → G1; H1 alongside D1/E1.

### EPIC A — App Shell & Journey Routing
- **A1 — Layout shell + global navigation.** `app/views/shared/_nav.html.erb` (authed nav + sign-out `button_to destroy_user_session_path, method: :delete`; login/signup when logged out); render in `app/views/layouts/application.html.erb`.
- **A2 — Public landing vs authed dashboard split.** New `DashboardController#show` (placeholder), `app/views/dashboard/show.html.erb`, route `get "dashboard"`; `pages#home` redirect when signed in; real landing in `app/views/pages/home.html.erb`. *(Reconcile #5.)* Depends on nothing hard; precedes A3.
- **A3 — Post-auth routing + onboarding state.** `ApplicationController#after_sign_in_path_for`/`after_sign_up_path_for`; `User` gets `has_many :ideas, dependent: :destroy`, `onboarding_complete?`, `next_onboarding_step`. Depends on A2.

### EPIC B — Creator Profile
- **B1 — Finish Creator profile.** Implement `CreatorsController#show`; fill `creators/show.html.erb`; fix `creator_params` (`:creators`→`:creator`); post-create redirect into onboarding. *(Supersedes #8; keep #4 fields, #7 preview as design follow-ups.)* Depends on A3.

### EPIC C — Ideas CRUD
- **C1 — IdeasController full CRUD + views** scoped to `current_user.ideas`. Fill `index`/`show`; create `new`/`edit`/`_form`/`_idea`. Show lists scripts + "Write a script" CTA. *(Distinct from AI idea feed #10/#11/#12; merges #32.)* Depends on A3.

### EPIC D — Scripts CRUD (nested + shallow)
- **D1 — ScriptsController + views.** Nested `index/new/create`, shallow `show/edit/update/destroy`; fill `index`/`new`/`show`, add `edit`/`_form`. Show has "Turn into LinkedIn post" CTA. Depends on C1.

### EPIC E — LinkedIn Posts CRUD (singular nested)
- **E1 — LinkedinPostsController + views.** `show/new/create/edit/update/destroy` via `@script.build_linkedin_post`; fill `new`/`show`, add `edit`/`_form`, remove dead `index`. Show CTAs to dashboard / new idea. Depends on D1.

### EPIC F — Polymorphic Chat + Creator-Aware LLM
- **F1 — `chattable` association.** Migration adding `chattable_type`/`chattable_id` to `chats` (+ index); `Chat belongs_to :chattable, polymorphic: true, optional: true`; `has_many :chats, as: :chattable` on User/Idea/Script/LinkedinPost. **Creator owns no chats** (see decision 4 — User is the single top-level owner). *(#34 and #29 already merged — no live coordination needed.)*
- **F2 — Wire chat entry points** into idea/script/post show pages reusing existing chat UI + `ChatResponseJob`. *(Supersedes #33; aligns with #15/#16.)* Depends on F1 + C1/D1/E1. **⚠️ SUPERSEDED** — reframed by the [Chat-driven Generation addendum](#addendum--chat-driven-generation-f2f4-reframe) below. *(F2's original "chat entry points on show pages" — without `new`-action redirects — is realized in the [Refine with AI addendum](#addendum--refine-with-ai-additional-journey).)*
- **F3 — Cascading context injection.** `app/services/llm_context.rb` walks ancestry (`LinkedinPost → Script → Idea → User → Creator`) building a layered system prompt: Idea→creator profile; Script→+parent idea; Post→+parent idea+parent script (incl. `scripts.system_prompt`). Apply via `chat.with_instructions(LlmContext.for(chattable))` in `ChatsController#create`. Depends on F1. **✅ DONE.**
- **F4 — Structured generation via `RubyLLM::Schema`.** `IdeaSchema{title,description,topic}`, `ScriptSchema{title,description,style,length}`, `LinkedinPostSchema{title,hook,body}` in `app/schemas/`; attach with `with_schema` on the generation path; parse JSON onto records. Free-form refinement stays schema-less. Depends on F2/F3. **⚠️ SUPERSEDED** — schema classes built; `with_schema` wiring is now folded into the [Chat-driven Generation addendum](#addendum--chat-driven-generation-f2f4-reframe) below.

### EPIC G — Dashboard content + onboarding guidance
- **G1 — Dashboard content + onboarding banner.** `DashboardController#show` loads `@creator`, `@ideas = current_user.ideas.includes(scripts: :linkedin_post)`, computes step; `dashboard/show.html.erb` + `_onboarding_banner.html.erb`. Depends on C1/D1/E1; uses A3 helpers.

### EPIC H — Authorization hardening
- **H1 — Cross-user authorization** for scripts/posts (find through `current_user`/`idea.user`); optional shared concern. Alongside D1/E1.

## Existing issues — disposition

- **Keep / design follow-ups:** #4 (fields, mostly done), #5 (welcome design → A2), #6 (LLM chat onboarding, deferred), #7 (profile preview), #10/#11/#12 (AI idea feed — separate track), #13/#14 (content studio), #17 (weekly hub).
- **Merge / supersede:** #8 → B1, #32 → C1, #33 → F2, #15/#16 → F2.
- **Coordinate:** #34, #29 with F1 (schema/seed for `chattable`).

## Team division (4 developers)

**Headline:** the dependency chain — not headcount — sets the pace. The critical path is 7 issues deep and strictly sequential:

```
A2 → A3 → C1 → D1 → E1 → F2 → F4
```

A script needs an idea; a post needs a script; chat wiring needs the show pages. So 4 devs ≈ the speed of this spine, with the side branches (A1, B1, F1, F3, G1, H1) done in parallel "for free" around it. Keep one focused owner driving the spine; absorb everything else alongside.

### Lanes (by ownership)

| Dev | Lane | Issues |
|-----|------|--------|
| **Dev 1** | Foundation & Dashboard | A2 → A3 → G1 |
| **Dev 2** | Content CRUD spine (pace-setter) | C1 → D1 → E1 |
| **Dev 3** | Chat & LLM | F1 → F3 → F2 → F4 |
| **Dev 4** | Shell, Profile & Auth | A1 → B1 → H1 |

### Wave schedule

| Wave | Dev 1 | Dev 2 | Dev 3 | Dev 4 |
|------|-------|-------|-------|-------|
| 1 | **A2** | *prep: shared `_form`/view + Tailwind kit* | **F1** | **A1** |
| 2 | **A3** | **C1** (← A3) | **F3** (← F1) | **B1** (← A3) |
| 3 | *pair on spine* | **D1** | **F2** idea-chat (← C1) | *UI polish / pair* |
| 4 | *pair on spine* | **E1** | **F2** extend to scripts | **H1** (alongside D1/E1) |
| 5 | **G1** (← E1) | review | **F2** finish (posts) → **F4** | review / E2E |

### Make it work
1. **A2 + A3 unblock everyone** — Dev 2 and Dev 4 are idle until A3 lands. Consider Dev 1 + Dev 2 **pairing on A2→A3 in Wave 1** to finish it a day early and shorten the whole project.
2. **Dev 2 is the bottleneck.** When Dev 1 frees up after A3, the highest-leverage move is to **pair on the C1→D1→E1 spine**, not start new side work.

### Coordination hotspots (shared files)
- `app/controllers/application_controller.rb` — A3 (Dev 1) + H1 (Dev 4). Mitigate: H1 lives in a concern (`app/controllers/concerns/`) with a one-line `include`.
- `app/models/user.rb` — A3 only (Dev 1).
- `app/views/layouts/application.html.erb` — A1 only (Dev 4).
- `config/routes.rb` — only A2 adds a route (resource routes already exist).
- `ChatsController#create` — F2 + F3, same owner (Dev 3).

With H1 as a concern, there is effectively no cross-dev file contention.

### Issue set (project #5 "Content Flow KanBan", label *Chat Refinement*)

**EPIC — Chat-driven Generation (RubyLLM).** Supersedes #48 (F2), #71 (F4), #33, #15, #16.

| Issue | Depends | Lane | Summary |
|---|---|---|---|
| **F-1** Chat `purpose` foundation | — | Dev 3 | migration + `enum purpose` + carry/persist through `chats#new/#create` + hidden field |
| **F-2** Generation engine | F-1, F-3 | Dev 3 | `resource :generation` + `GenerationPlan` + `GenerationsController#create` + `current_user_linkedin_posts` |
| **F-3** `with_schema` spike + JSON fallback (day-1 hard gate) | — | Dev 1 | verify schema vs endpoint; build the reusable fallback |
| **F-4** Generate entry points + dead-code cleanup | F-1 | Dev 2 | redirect the three `new` actions; remove `generate_idea` stub + readonly |
| **F-5** Chat-show "save as …" action + styling | F-2 | Dev 4 | conditional `button_to`; restyle chat show/composer to DESIGN.md |
| **F-6** Tests + E2E | F-2,F-4,F-5 | pairing | request specs per purpose + first-run journey; `bin/rails test` green |
| *Deferred* Refine via chat | EPIC | — | add `refine_*` purposes + show-page links + update rows in `GenerationPlan` (folds in #15/#16) |

### 5-day sequencing (4 devs)

Critical path: **F-3 gate (day 1) → F-1 → F-2 → F-5 → F-6**, mostly owned by Dev 3.

| Day | Dev 3 (Chat&LLM) | Dev 1 (de-risk) | Dev 2 (Content CRUD) | Dev 4 (Shell/UI) |
|---|---|---|---|---|
| 1 | **F-1** | **F-3** spike — gate by EOD | other feature | chat UI restyle groundwork |
| 2 | **F-2** start | support F-2 | **F-4** (after F-1) | other feature |
| 3 | **F-2** finish | start **F-5** controller side | **F-4** done → other | **F-5** styling (after F-2) |
| 4 | pair **F-6** specs | **F-6** specs (pair) | other feature | **F-5** + polish |
| 5 | review/buffer | **F-6** + E2E | other feature | E2E + polish |

Merge **F-1 fast** (unblocks F-4); **F-2 is the bottleneck** — once it lands (~day 3) Devs 2/4 roll
onto other features. Coordination is low: F-1/F-2 touch chat files (Dev 3 only); F-4 touches content
`new` actions + `ideas/_form` (Dev 2); F-5 touches `chats/show` (Dev 4); the one shared file is
`config/routes.rb` (F-2 adds the generation route, F-4 removes `generate_idea`).

### Issue set (project #5 "Content Flow KanBan", label *Chat Refinement*)

**EPIC — Refine with AI (RubyLLM).** Additive to (not superseding) the generate EPIC #82; realizes
the intent of #89; independent of `GenerationsController`/`purpose`.

| Issue | Depends | Summary |
|---|---|---|
| **R-1** Chat entry points from show pages (original F2) | — (F1 done) | hidden chattable fields in `chats/_form`; `ChatsController#new` seeds `@chat`; "refine with ai" CTA on the three show pages — **no** `new`-action redirects |
| **R-2** Refinement engine | R-1, #84 | `resource :refinement` + `RefinementsController#create` + `current_user_linkedin_posts`; authorize via user-scoped `.find`; empty-transcript guard; model-string fix; refine directive (overwrite-keep-undiscussed); prompt-JSON fallback; non-bang `update` + error branch; correct redirects incl. singular post |
| **R-3** Apply button + chat-show styling | R-2 | conditional `button_to` gated on chattable type + visible messages; restyle `chats/show` + composer to DESIGN.md |
| **R-4** Tests + E2E | R-2, R-3 | request specs per chattable type (happy / non-owner 404 / empty transcript / fallback / validation failure / undiscussed-field protection); `chats#new` hidden-field test; create→refine→apply E2E |

**#84 (F-3 `with_schema` spike + fallback)** is shared infrastructure — R-2 reuses it, no
duplication. **#89** stays open and is cross-linked (the team may close it in favor of this EPIC).
The generate issues **#82–#88 are left untouched**.

### Sequencing (brief)

Critical path: **R-1 → R-2 → R-3 → R-4** (mostly Chat&LLM dev). R-1 is small and unblocks both R-2
and the show-page CTAs; **R-2 is the bottleneck** (the engine); once it lands, R-3 (UI) and R-4
(tests) open. #84's fallback is the only cross-track dependency and is already scheduled in the
generate track. Total ≈ **3–4 dev-days**.