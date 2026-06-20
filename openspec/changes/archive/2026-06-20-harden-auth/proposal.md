## Why

Authentication accepts weak passwords (6-char minimum, no complexity), uses a
permissive email regex that allows addresses without a TLD, and does not verify
that users own the email they register with. These gaps leave the app vulnerable
to credential-stuffing, typo-squatting, and ghost accounts. Issue #5 scopes the
hardening work.

## What Changes

- **Email format validation**: Replace Devise's loose regex with a stricter
  pattern requiring a valid local part, domain with at least one dot, and a TLD.
- **Password strength**: Raise the minimum length to 15 characters and require at
  least one number and one symbol (any non-alphanumeric character). Existing
  users are not forced to reset — the new rules apply on create/update only.
- **Email verification**: Enable Devise `:confirmable` so users must click a
  confirmation link before accessing the app. No grace period. Existing users
  are backfilled as confirmed.
- **Email infrastructure**: Configure Postmark (direct account) as the production
  SMTP relay via Rails Action Mailer. Add `letter_opener` for development email
  catching. Clean up placeholder sender addresses.

## Capabilities

### New Capabilities

- `email-verification`: Email confirmation flow — users must verify their email
  address before accessing the app. Covers the confirmation lifecycle,
  reconfirmation on email change, and the "resend confirmation" path.
- `email-delivery`: Transactional email infrastructure — Postmark SMTP for
  production, letter_opener for development, sender address configuration.

### Modified Capabilities

- `auth-onboarding`: Post-sign-up flow changes. With `:confirmable` and no grace
  period, the user must confirm their email before reaching the onboarding
  redirect. The sign-up → creator-profile path now has a confirmation gate.
- `authorization`: Password and email validation rules are tightened — stronger
  regex, longer minimum, complexity requirements.

## Impact

- **Config**: `config/initializers/devise.rb` (email regex, password length,
  mailer sender), `config/environments/development.rb` (delivery method),
  `config/environments/production.rb` (SMTP settings).
- **Model**: `app/models/user.rb` (`:confirmable` module, password complexity
  validation).
- **Mailer**: `app/mailers/application_mailer.rb` (sender address).
- **Database**: New migration adding confirmable columns to `users`, backfilling
  existing rows.
- **Dependencies**: `letter_opener` gem added to development group. No new
  production gems — Rails Action Mailer handles SMTP natively.
- **External**: Postmark account required. Domain DNS records (SPF, DKIM) must
  be configured for production email delivery.
