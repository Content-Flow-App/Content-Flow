## MODIFIED Requirements

### Requirement: Post-authentication routing
The system SHALL route a user after sign-in and sign-up based on whether they
have a creator profile. A user without a creator profile SHALL be sent to the
creator profile form; a user with a creator profile SHALL be sent to the
dashboard. Routing SHALL be implemented by overriding `after_sign_in_path_for` /
`after_sign_up_path_for` rather than a global `before_action` wizard lock.

With `:confirmable` enabled and no grace period, the post-sign-up redirect SHALL
only fire after the user has confirmed their email and signed in. The sign-up
action itself SHALL display a "check your email" notice instead of redirecting to
the creator profile. The onboarding redirect to `new_creator_path` SHALL occur on
the first confirmed sign-in.

#### Scenario: New user signs up (with confirmation required)
- **WHEN** a user completes sign-up
- **THEN** the system displays a confirmation-pending notice instead of
  redirecting to `new_creator_path`

#### Scenario: Newly confirmed user signs in without creator profile
- **WHEN** a user confirms their email and signs in for the first time, having no
  creator profile
- **THEN** the system redirects them to `new_creator_path`

#### Scenario: Existing user with creator profile signs in
- **WHEN** a user signs in and already has a creator profile
- **THEN** the system redirects them to `dashboard_path`
