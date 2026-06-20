## ADDED Requirements

### Requirement: Instagram post as a singular resource nested under a script
The system SHALL provide an Instagram post as a singular resource nested under a script, supporting `show`, `new`, `create`, `edit`, `update`, and `destroy`. A new post SHALL be built through `@script.build_instagram_post`. An Instagram post SHALL capture `title`, `hook`, and `body`. There SHALL be no `index` action for Instagram posts. The `script_id` foreign key SHALL be nullable so a post can instead belong directly to an idea.

#### Scenario: User creates an Instagram post for a script
- **WHEN** an authenticated user submits the new Instagram post form under one of their scripts
- **THEN** the system builds the post via `@script.build_instagram_post`, persists it, and redirects to `script_instagram_post_path(script)`

#### Scenario: A script has at most one Instagram post
- **WHEN** a script already has an Instagram post and the user opens its new/edit flow
- **THEN** the system operates on that single post rather than creating a collection

### Requirement: Instagram post belongs to exactly one parent
The system SHALL allow an Instagram post to belong to **either** a script (scripted flow) **or** an idea (direct flow), never both and never neither. The post SHALL expose `parent_idea` (resolving to `script&.idea || idea`) and SHALL derive its owning user through that parent idea. A validation SHALL reject a post that has both `script_id` and `idea_id` set, or neither.

#### Scenario: Post with a single parent is valid
- **WHEN** an Instagram post is saved with exactly one of `script_id` or `idea_id` present
- **THEN** the post is valid and `parent_idea` resolves to the idea behind that parent

#### Scenario: Post with two parents is rejected
- **WHEN** an Instagram post is saved with both `script_id` and `idea_id` present
- **THEN** the validation fails with an error that it must belong to either a script or an idea, not both

#### Scenario: Post with no parent is rejected
- **WHEN** an Instagram post is saved with neither `script_id` nor `idea_id` present
- **THEN** the validation fails because a parent is required

### Requirement: Instagram post created directly from an idea
The system SHALL provide an Instagram post as a singular resource nested directly under an idea, supporting `show`, `new`, `create`, `edit`, `update`, and `destroy`, in addition to the existing script-nested resource. A directly-created post SHALL be built through the idea's `instagram_posts` association and SHALL redirect to `idea_instagram_post_path(idea)` after a successful create.

#### Scenario: User creates an Instagram post directly from an idea
- **WHEN** an authenticated user submits the new Instagram post form nested under one of their ideas
- **THEN** the system builds the post on that idea, persists it with no script parent, and redirects to `idea_instagram_post_path(idea)`

#### Scenario: Parent is resolved from whichever route is used
- **WHEN** the post controller runs with `params[:script_id]` versus `params[:idea_id]`
- **THEN** it resolves the parent to the user-scoped script in the first case and the user-scoped idea in the second
