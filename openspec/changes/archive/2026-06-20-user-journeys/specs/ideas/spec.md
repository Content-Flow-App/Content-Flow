## ADDED Requirements

### Requirement: Ideas CRUD scoped to the current user
The system SHALL provide full CRUD for ideas (`index`, `show`, `new`, `create`, `edit`, `update`, `destroy`) with every action scoped through `current_user.ideas`. An idea SHALL capture `title`, `description`, and `topic`.

#### Scenario: User lists their own ideas
- **WHEN** an authenticated user visits the ideas index
- **THEN** the system lists only ideas belonging to `current_user`

#### Scenario: User creates an idea
- **WHEN** an authenticated user submits the new idea form with a valid title, description, and topic
- **THEN** the system creates the idea owned by `current_user` and redirects to it

### Requirement: Idea show page links to scripts
The system SHALL show, on an idea's detail page, the scripts that belong to that idea and a "Write a script" call to action leading to the new-script form for that idea.

#### Scenario: Idea detail page offers script creation
- **WHEN** an authenticated user views one of their ideas
- **THEN** the page lists the idea's scripts and displays a "Write a script" CTA targeting the new-script form for that idea
