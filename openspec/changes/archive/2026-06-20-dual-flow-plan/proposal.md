# Dual-Flow Plan — Idea → Post & Idea → Script → Post

> Written 2026-06-10. Extends the existing architecture to support two parallel
> content creation journeys without breaking either one.

## The two flows

| Flow | Path |
|---|---|
| **Direct** (new) | Idea → Platform Post |
| **Scripted** (existing) | Idea → Script → Platform Post |

---

## The gap

Posts (`linkedin_posts`, `twitter_posts`, `instagram_posts`) currently require a
`script_id` — the schema enforces it as a non-null FK. The existing controllers
always load a `@script` parent and build posts via `@script.build_linkedin_post`.
There is no path from an idea to a post without a script in between.

---

## Recommended approach: dual nullable FK

Add an `idea_id` FK to each post table and make `script_id` nullable. A post
then belongs to **either** a script or an idea directly — never both. The
scripted path is completely unchanged; the direct path is a second optional
branch layered on top.

## What stays the same

- All existing `idea → script → post` routes, controllers, views, and tests.
- `LlmContext` walk order for the scripted path.
- `StructuredExtraction` / `StructuredContent` services.
- Chat polymorphism (`chattable`).
- `RefinementsController` — refine a post by its existing chattable, regardless
  of parent path.

---

## Tradeoffs

| | Dual FK (this plan) | Polymorphic parent |
|---|---|---|
| DB change | 3 small migrations | Bigger schema refactor |
| Existing routes/tests | **Unchanged** | All post routes change |
| Controller complexity | Two branches, clear intent | Single generic branch |
| `has_one` helpers | Need manual guard on Idea side | Automatic via polymorphism |
| Overall risk | Low — additive only | Medium — touches all post paths |

Dual FK is the conservative, additive choice. A polymorphic parent would be
cleaner long-term if more parent types are expected; for two known parents the FK
approach is simpler and lower-risk.

