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

## JavaScript

All JavaScript must be written as Stimulus controllers. No inline scripts or bare `addEventListener` calls.

## Design & Styling

Designs are created in Figma and provided to Claude Code via MCP. When given a design, apply the following guidelines:

- **Templates** — this project uses `.html.erb` files for all views.
- **CSS approach** — use Tailwind CSS as the first resort. Only reach for custom CSS if a design requirement cannot be achieved with Tailwind utility classes.
- **Custom CSS** — if custom CSS is needed, create a dedicated partial stylesheet in `app/assets/stylesheets/` and import it in `tailwind.css`. Do not add custom styles inline or in a shared global file.
- **Model requirements** — if the design relates to a specific model, review the model file, the schema, and the controller before implementing. Confirm that all required form fields or displayable data columns are already supported; if not, flag the gap before writing any view code.
