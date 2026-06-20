## ADDED Requirements

### Requirement: Scripts nested under ideas with shallow routes
The system SHALL provide scripts as a resource nested under ideas for `index`, `new`, and `create`, and as shallow routes for `show`, `edit`, `update`, and `destroy`. A script SHALL capture `title`, `description`, `style`, and `length` and belong to an idea.

#### Scenario: User creates a script for an idea
- **WHEN** an authenticated user submits the new-script form under one of their ideas
- **THEN** the system creates the script associated with that idea and redirects to the script

#### Scenario: User opens a script by its shallow route
- **WHEN** an authenticated user visits a script's show page
- **THEN** the system renders the script via the shallow `script_path` without requiring the parent idea in the URL

### Requirement: Script show page links to LinkedIn post creation
The system SHALL display, on a script's detail page, a "Turn into LinkedIn post" call to action leading to the new LinkedIn post for that script.

#### Scenario: Script detail page offers post creation
- **WHEN** an authenticated user views one of their scripts
- **THEN** the page shows a "Turn into LinkedIn post" CTA targeting the new LinkedIn post for that script
