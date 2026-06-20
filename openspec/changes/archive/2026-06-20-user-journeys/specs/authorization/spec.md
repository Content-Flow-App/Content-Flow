## ADDED Requirements

### Requirement: Cross-user authorization for content records
The system SHALL authorize access to scripts and LinkedIn posts through ownership rather than direct lookup, since these records carry no `user_id`. Scripts SHALL be resolved through `idea.user`, and LinkedIn posts through `current_user_linkedin_posts` (`LinkedinPost.joins(script: :idea).where(ideas: { user_id: current_user.id })`). A request for a record the user does not own SHALL be blocked.

#### Scenario: Owner accesses their script
- **WHEN** a user requests one of their own scripts
- **THEN** the system resolves it through `current_user` ownership and renders it

#### Scenario: Non-owner is blocked from a script
- **WHEN** user B requests user A's `script_path`
- **THEN** the user-scoped lookup fails and access is blocked

#### Scenario: Non-owner is blocked from a LinkedIn post
- **WHEN** user B requests user A's `linkedin_post_path`
- **THEN** the user-scoped lookup fails and access is blocked
