## ADDED Requirements

### Requirement: LinkedIn post as a singular resource nested under a script
The system SHALL provide a LinkedIn post as a singular resource nested under a script, supporting `show`, `new`, `create`, `edit`, `update`, and `destroy`. A new post SHALL be built through `@script.build_linkedin_post`. A LinkedIn post SHALL capture `title`, `hook`, and `body`. There SHALL be no `index` action for LinkedIn posts.

#### Scenario: User creates a LinkedIn post for a script
- **WHEN** an authenticated user submits the new LinkedIn post form under one of their scripts
- **THEN** the system builds the post via `@script.build_linkedin_post`, persists it, and redirects to `script_linkedin_post_path(script)`

#### Scenario: A script has at most one LinkedIn post
- **WHEN** a script already has a LinkedIn post and the user opens its new/edit flow
- **THEN** the system operates on that single post rather than creating a collection

### Requirement: LinkedIn post show page links onward
The system SHALL display, on a LinkedIn post's detail page, calls to action leading to the dashboard and to creating a new idea.

#### Scenario: Post detail page offers onward navigation
- **WHEN** an authenticated user views a LinkedIn post
- **THEN** the page shows CTAs to the dashboard and to creating a new idea
