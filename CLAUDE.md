# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Stack: Ruby 3.3.5, Rails 8.1.1, PostgreSQL, Tailwind, Propshaft
<!-- This needs to be changed to reflect project setups -->

### Rails conventions and "magic"

This is a teaching project. For the following Rails conventions, always explain what is happening and show the equivalent explicit code:

- **`resources`** — what routes it generates and what each maps to
- **Member routes** — what `member do` adds and how it differs from a plain `get`
- **Collection routes** — same treatment as member routes
- **Implicit template lookup** — when a controller action renders without an explicit `render` call, explain which file Rails finds and why

### Branch context

At the start of any work on a branch, check the branch name for an issue number. If one is present (e.g. `feature/42-add-reviews`), run `gh issue view <number>` and use the title, description, and comments as context before starting.

### Commits

While working on a branch, suggest good moments to commit and briefly explain why it is a natural checkpoint (e.g. a feature is working, a refactor is complete, tests pass, a logical unit of work is done).

### Refactoring

When making a refactor, always explain what is changing and why it is beneficial before making the change.

## Design

@DESIGN.md

## JavaScript

All JavaScript must be written as Stimulus controllers. No inline scripts or bare `addEventListener` calls.

## Specs
Behavioral specs are in `openspec/specs/`. Consult the relevant domain
spec before implementing any feature in that area.
