## ADDED Requirements

### Requirement: Production email delivery via Postmark API
The system SHALL deliver transactional emails in production through the Postmark
API using the `postmark-rails` gem. The Server API Token SHALL be stored in Rails
encrypted credentials as `postmark_api_token`, not environment variables or
plain-text config. The delivery method SHALL be `:postmark`.

#### Scenario: Devise sends a confirmation email in production
- **WHEN** a user signs up in the production environment
- **THEN** the confirmation email is delivered through the Postmark API

#### Scenario: API token is missing
- **WHEN** the application attempts to send email in production without a
  `postmark_api_token` in Rails credentials
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
