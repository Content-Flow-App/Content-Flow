## Implementation order

1. **Migrations** — add `idea_id`, make `script_id` nullable on all three post tables.
2. **Models** — `optional:` associations, `requires_exactly_one_parent` validation,
   `parent_idea` / `user` delegates, `has_many` on `Idea`.
3. **Routes** — add idea-nested post resources.
4. **Controllers** — `set_parent` branch, `UserScopedResource` helper.
5. **`LlmContext`** — nil-safe script skip.
6. **`GenerationPlan`** — Idea as valid chattable for post generation.
7. **Idea `show` view** — direct-posts section + dual CTAs.
8. **Onboarding** — satisfy `:post` step from either path.
9. **Tests** — request specs for direct path; verify scripted path unchanged.

