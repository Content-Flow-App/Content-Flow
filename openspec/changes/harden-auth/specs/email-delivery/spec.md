## ADDED Requirements

### Requirement: Production email delivery via SMTP
The system SHALL deliver transactional emails in production through an external
SMTP relay (Postmark). SMTP credentials SHALL be stored in Rails encrypted
credentials, not environment variables or plain-text config. The delivery method
SHALL be `:smtp` with TLS enabled.

#### Scenario: Devise sends a confirmation email in production
- **WHEN** a user signs up in the production environment
- **THEN** the confirmation email is delivered through the configured Postmark
  SMTP relay

#### Scenario: SMTP credentials are missing
- **WHEN** the application starts in production without SMTP credentials in
  Rails credentials
- **THEN** email delivery fails with a clear error rather than silently dropping
  messages

### Requirement: Development email catching
The system SHALL intercept all outgoing emails in the development environment and
display them in the browser instead of delivering them. This SHALL be implemented
using the `letter_opener` gem with `delivery_method: :letter_opener`.

#### Scenario: Developer triggers a confirmation email locally
- **WHEN** a developer signs up a user in the development environment
- **THEN** the confirmation email opens in a new browser tab instead of being
  sent to an SMTP server

### Requirement: Consistent sender address
The system SHALL use a single, consistent sender email address across all
transactional emails. The address SHALL be configured in both
`Devise.mailer_sender` and `ApplicationMailer`'s default `from`. Placeholder
addresses (`@example.com`) SHALL be replaced.

#### Scenario: User receives a Devise email
- **WHEN** any Devise email (confirmation, password reset, etc.) is sent
- **THEN** the `From` address matches the configured sender domain

### Requirement: Async email delivery
The system SHALL queue transactional emails for background delivery using
`deliver_later` and Solid Queue rather than blocking the request cycle with
synchronous delivery.

#### Scenario: Sign-up does not block on email delivery
- **WHEN** a user signs up and a confirmation email is triggered
- **THEN** the email is enqueued to Solid Queue and the HTTP response returns
  without waiting for SMTP delivery
