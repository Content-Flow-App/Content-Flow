## 1. Email & password validation

- [x] 1.1 In `config/initializers/devise.rb`, change `config.password_length` from `6..128` to `15..128`
- [x] 1.2 In `config/initializers/devise.rb`, replace `config.email_regexp` with `/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i`
- [x] 1.3 In `app/models/user.rb`, add `validate :password_complexity` with checks for at least one digit (`/\d/`) and at least one symbol (`/[^a-zA-Z\d\s]/`)

## 2. Confirmable migration & model

- [x] 2.1 Generate migration to add `confirmation_token` (string, indexed unique), `confirmed_at` (datetime), `confirmation_sent_at` (datetime), and `unconfirmed_email` (string) to `users`
- [x] 2.2 In the same migration, backfill all existing users: `UPDATE users SET confirmed_at = NOW() WHERE confirmed_at IS NULL`
- [x] 2.3 In `app/models/user.rb`, add `:confirmable` to the `devise` modules line
- [x] 2.4 Run migration and verify existing users have `confirmed_at` set

## 3. Mailer infrastructure — development

- [ ] 3.1 Add `gem "letter_opener"` to the `:development` group in `Gemfile` and run `bundle install`
- [ ] 3.2 In `config/environments/development.rb`, set `config.action_mailer.delivery_method = :letter_opener`
- [ ] 3.3 Verify: sign up a user in development and confirm the email opens in a browser tab

## 4. Mailer infrastructure — production

- [ ] 4.1 In `config/environments/production.rb`, uncomment and configure `config.action_mailer.smtp_settings` with Postmark SMTP (`smtp.postmarkapp.com`, port 587, `authentication: :plain`, `enable_starttls: true`, credentials from `Rails.application.credentials.dig(:smtp, ...)`)
- [ ] 4.2 Set `config.action_mailer.delivery_method = :smtp` in `config/environments/production.rb`
- [ ] 4.3 Add SMTP credentials to Rails encrypted credentials via `bin/rails credentials:edit` (keys: `smtp.user_name`, `smtp.password`)
- [ ] 4.4 Verify `config.action_mailer.raise_delivery_errors = true` is set in production so failed sends surface rather than silently drop

## 5. Sender address cleanup

- [ ] 5.1 In `config/initializers/devise.rb`, replace `config.mailer_sender` placeholder with real sender address matching the verified Postmark domain
- [ ] 5.2 In `app/mailers/application_mailer.rb`, update `default from:` to match the Devise sender

## 6. Verification & smoke test

- [ ] 6.1 In development: register a new user, verify confirmation email appears via letter_opener, click link, confirm sign-in works
- [ ] 6.2 In development: sign in with an existing user (backfilled), verify no confirmation is required
- [ ] 6.3 In development: attempt registration with a weak password (short, no number, no symbol) and verify each error message
- [ ] 6.4 In development: attempt registration with an invalid email (no TLD) and verify rejection
- [ ] 6.5 Verify the onboarding flow: confirmed sign-in without a creator profile redirects to `new_creator_path`
