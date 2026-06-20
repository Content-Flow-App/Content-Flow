# app-shell

## Purpose

Provide the application layout chrome: a shared navigation partial that adapts to
auth state, and the split between the public landing page and the authenticated
dashboard.

## Requirements

### Requirement: Global navigation
The system SHALL render a shared navigation partial in the application layout. When a user is signed in, the navigation SHALL show authenticated links and a sign-out control that issues a `DELETE` to `destroy_user_session_path`. When no user is signed in, the navigation SHALL show login and sign-up links.

#### Scenario: Signed-in user sees authenticated navigation
- **WHEN** a signed-in user loads any page
- **THEN** the navigation shows authenticated links and a sign-out control that submits a DELETE request to end the session

#### Scenario: Signed-out visitor sees public navigation
- **WHEN** a visitor who is not signed in loads a page
- **THEN** the navigation shows login and sign-up links

### Requirement: Public landing versus authenticated dashboard
The system SHALL keep `pages#home` publicly accessible as the landing page. When a signed-in user visits the landing page, the system SHALL redirect them to the dashboard.

#### Scenario: Visitor sees the public landing page
- **WHEN** a visitor who is not signed in requests the home page
- **THEN** the system renders the public landing page without requiring authentication

#### Scenario: Signed-in user is redirected from landing to dashboard
- **WHEN** a signed-in user requests the home page
- **THEN** the system redirects them to `dashboard_path`
