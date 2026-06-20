## MODIFIED Requirements

### Requirement: Email format validation
The system SHALL validate email addresses using a regex that enforces: word
characters, `+`, `-`, and `.` in the local part; an alphanumeric domain with
optional hyphens; at least one dot separating domain labels; and a TLD of one or
more alpha characters. The regex SHALL be case-insensitive. Addresses without a
TLD (e.g. `user@localhost`) SHALL be rejected.

#### Scenario: Valid email is accepted
- **WHEN** a user registers with `creator@example.com`
- **THEN** the system accepts the email format

#### Scenario: Email without TLD is rejected
- **WHEN** a user registers with `creator@localhost`
- **THEN** the system rejects the email with a format error

#### Scenario: Email with subdomain is accepted
- **WHEN** a user registers with `creator@mail.example.co.uk`
- **THEN** the system accepts the email format

#### Scenario: Email with special local-part characters is accepted
- **WHEN** a user registers with `first+tag@example.com`
- **THEN** the system accepts the email format

### Requirement: Password strength
The system SHALL require passwords to be between 15 and 128 characters, contain
at least one numeric digit, and contain at least one symbol (any character that
is not a letter, digit, or whitespace). These rules SHALL apply only when a
password is being set or changed — existing users are not forced to update on
sign-in.

#### Scenario: Strong password is accepted
- **WHEN** a user sets their password to `MyStr0ngP@ssword!`
- **THEN** the system accepts the password

#### Scenario: Password too short is rejected
- **WHEN** a user sets their password to `Short1!`
- **THEN** the system rejects the password with a minimum-length error

#### Scenario: Password without a number is rejected
- **WHEN** a user sets their password to `NoNumbersHere!!!`
- **THEN** the system rejects the password with a "must include a number" error

#### Scenario: Password without a symbol is rejected
- **WHEN** a user sets their password to `NoSymbolsHere123`
- **THEN** the system rejects the password with a "must include a symbol" error

#### Scenario: Existing user signs in with old weak password
- **WHEN** a user who set a 6-character password before the policy change signs in
- **THEN** the system allows sign-in because validation runs on set/change only
