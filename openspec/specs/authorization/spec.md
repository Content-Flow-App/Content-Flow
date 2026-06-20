# authorization

## Purpose

Scripts and LinkedIn posts carry no `user_id`, so access control runs through
ownership of the parent idea. Requests for records the user does not own are
blocked.

## Requirements

### Requirement: Cross-user authorization for content records
The system SHALL authorize access to scripts and LinkedIn posts through ownership rather than direct lookup, since these records carry no `user_id`. Scripts SHALL be resolved through `idea.user`. LinkedIn posts SHALL be resolved through `current_user_linkedin_posts`, which SHALL cover **both** parent paths — a post owned via its script's idea **or** via its directly-attached idea — by left-joining both associations and matching either idea's `user_id` to the current user. A request for a record the user does not own SHALL be blocked.

#### Scenario: Owner accesses their script
- **WHEN** a user requests one of their own scripts
- **THEN** the system resolves it through `current_user` ownership and renders it

#### Scenario: Non-owner is blocked from a script
- **WHEN** user B requests user A's `script_path`
- **THEN** the user-scoped lookup fails and access is blocked

#### Scenario: Owner accesses a directly-created post
- **WHEN** a user requests a LinkedIn post they created directly from their own idea
- **THEN** `current_user_linkedin_posts` resolves it through the idea path and access is allowed

#### Scenario: Non-owner is blocked from a LinkedIn post
- **WHEN** user B requests user A's LinkedIn post by either the script-nested or idea-nested path
- **THEN** the user-scoped lookup fails and access is blocked
