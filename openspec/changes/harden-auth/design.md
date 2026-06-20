## Context

The app uses Devise with `:database_authenticatable`, `:registerable`,
`:recoverable`, `:rememberable`, and `:validatable`. The `users` table has the
standard Devise columns but no confirmable fields. Mailer configuration exists
in skeleton form — `development.rb` and `production.rb` have `default_url_options`
set but no delivery method or SMTP settings. Solid Queue is already configured
for background jobs in production. The `ApplicationMailer` and `devise.rb` both
use placeholder `@example.com` sender addresses.

Post-sign-up routing is handled by overriding `after_sign_in_path_for` /
`after_sign_up_path_for` in a custom Devise controller, directing users to
`new_creator_path` or `dashboard_path` based on creator profile existence.

## Goals / Non-Goals

**Goals:**

- Enforce email format, password length, and password complexity at registration
  and password change
- Require email verification before a user can access authenticated pages
- Set up reliable transactional email delivery for production (Postmark) and
  development (letter_opener)
- Preserve access for existing users — no lockouts, no forced resets

**Non-Goals:**

- Account lockout after failed attempts (`:lockable`) — separate concern
- Session timeout (`:timeoutable`) — separate concern
- OAuth / social login — out of scope
- Custom Devise mailer views / styling — can follow later
- Rate limiting on confirmation resend — not in scope

## Decisions

### 1. Keep `:validatable` and layer custom validation on top

**Choice**: Keep Devise's `:validatable` module and add a `validate
:password_complexity` method on User.

**Why**: `:validatable` already handles password length, presence, confirmation
matching, and email format. Dropping it to own all validation means reimplementing
tested logic. The custom method only adds the two complexity checks (digit +
symbol) that Devise doesn't support.

**Alternative considered**: Remove `:validatable` and write all validations
manually. Rejected — more code, more maintenance, same result.

### 2. Symbol = any non-alphanumeric character

**Choice**: Use `/[^a-zA-Z\d\s]/` for symbol detection.

**Why**: A specific allowlist (`!@#$%^&*`) frustrates users who pick a valid
symbol not in the list (e.g. `_`, `~`, `€`). "Anything that isn't a letter,
digit, or whitespace" is inclusive and simple.

**Alternative considered**: Explicit symbol allowlist. Rejected — arbitrary and
annoying.

### 3. Email regex: practical strictness, not RFC-5322

**Choice**: `/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i`

**Why**: Covers 99.9% of real-world email addresses. Rejects obvious junk
(`user@localhost`, `@`, spaces). Full RFC-5322 compliance allows quoted strings
and IP-literal domains that no real user types. The real validation is the
confirmation email itself.

**Alternative considered**: Full RFC-5322 regex. Rejected — hundreds of
characters, allows formats no one uses, false sense of completeness.

### 4. Postmark via SMTP, not the Postmark API gem

**Choice**: Use Rails' built-in `delivery_method: :smtp` with Postmark's SMTP
endpoint. No `postmark-rails` gem.

**Why**: Stays in the framework. Action Mailer speaks SMTP natively. The
Postmark-specific gem adds API-mode delivery and extras (delivery stats, bounce
handling) that aren't needed yet. SMTP is the universal transport — switching
providers later means changing four config lines, not swapping a gem.

**Alternative considered**: `postmark-rails` gem for API-mode delivery. Rejected
— unnecessary dependency for transactional email.

### 5. Credentials in Rails encrypted credentials, not ENV vars

**Choice**: Store SMTP username/password via `bin/rails credentials:edit`.

**Why**: Rails convention. Encrypted at rest, version-controlled, no risk of
leaking in `heroku config` output or `.env` files. The production.rb scaffold
already references `Rails.application.credentials.dig(:smtp, ...)`.

**Alternative considered**: Heroku config vars / ENV. Rejected — less secure,
not the Rails way.

### 6. letter_opener for development, not :log or mailcatcher

**Choice**: `letter_opener` gem in the development group.

**Why**: Opens emails in the browser automatically when triggered — closest to
the real user experience. The `:log` method dumps HTML to the console (unreadable
for styled emails). Mailcatcher requires running a separate process. Rails mailer
previews are useful for design iteration but don't catch emails from real flows.

**Alternative considered**: `:log` delivery method (zero gems). Rejected — HTML
in terminal is painful for confirmation emails with links.

### 7. Backfill existing users in the migration

**Choice**: Set `confirmed_at = Time.current` for all existing users in the same
migration that adds the confirmable columns.

**Why**: Single atomic operation. No window where existing users are locked out.
Reversible if the migration is rolled back.

**Alternative considered**: Separate rake task. Rejected — introduces a gap
between schema change and data fix.

## Risks / Trade-offs

**[Postmark free tier limit]** → 100 emails/month. Sufficient for early stage.
Monitor usage; upgrade to Basic ($15/mo) when approaching the cap.

**[DNS verification required]** → Postmark requires SPF and DKIM DNS records for
the sending domain. Emails won't deliver until DNS is configured. Mitigation:
this is a one-time setup step, documented in tasks.

**[Existing weak passwords still valid]** → Users with 6-char passwords can
still sign in. This is intentional — forcing resets risks locking out users and
generating support load. They'll hit the new rules on their next password change.

**[letter_opener opens browser tabs]** → Every email in dev opens a tab. Can be
noisy during heavy testing. Mitigation: switch to `letter_opener_web` later if
it becomes annoying (provides a web UI at `/letter_opener` instead of new tabs).

**[No rate limiting on confirmation resend]** → A user could spam the resend
endpoint. Devise has some built-in throttling (won't resend if a recent token
exists). Full rate limiting is out of scope but noted for future hardening.
