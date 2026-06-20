## ADDED Requirements

### Requirement: Email confirmation before access
The system SHALL require users to confirm their email address before they can
access any authenticated page. A newly registered user SHALL receive a
confirmation email containing a unique token link. Clicking the link SHALL mark
the account as confirmed and allow sign-in. Until confirmed, any sign-in attempt
SHALL be rejected with a message indicating the account is unconfirmed.

#### Scenario: New user signs up and receives confirmation email
- **WHEN** a user submits the registration form with valid credentials
- **THEN** the system creates an unconfirmed account and sends a confirmation
  email to the provided address

#### Scenario: Unconfirmed user attempts to sign in
- **WHEN** an unconfirmed user attempts to sign in with correct credentials
- **THEN** the system rejects the sign-in and displays a message that the account
  must be confirmed first

#### Scenario: User confirms their email
- **WHEN** a user clicks the confirmation link from their email
- **THEN** the system marks the account as confirmed and redirects to sign-in

### Requirement: Reconfirmation on email change
The system SHALL require reconfirmation when a confirmed user changes their email
address. The new email SHALL be stored as `unconfirmed_email` until the user
clicks a confirmation link sent to the new address. The original email SHALL
remain active until the new one is confirmed.

#### Scenario: Confirmed user changes their email
- **WHEN** a confirmed user updates their email address
- **THEN** the system sends a confirmation email to the new address and keeps the
  original email active until the new one is confirmed

#### Scenario: User confirms their new email
- **WHEN** a user clicks the reconfirmation link sent to their new email
- **THEN** the system replaces the original email with the new one

### Requirement: Resend confirmation
The system SHALL provide a way for unconfirmed users to request a new
confirmation email. The system SHALL generate a new token and invalidate any
previous confirmation token.

#### Scenario: User requests a new confirmation email
- **WHEN** an unconfirmed user requests a resend of the confirmation email
- **THEN** the system sends a new confirmation email with a fresh token

### Requirement: Existing users are backfilled as confirmed
The system SHALL mark all existing user accounts as confirmed during the
migration so that they are not locked out. The `confirmed_at` column SHALL be set
to the migration timestamp for all rows where it is NULL.

#### Scenario: Migration runs on a database with existing users
- **WHEN** the confirmable migration executes
- **THEN** all existing users have `confirmed_at` set and can continue signing in
  without interruption
