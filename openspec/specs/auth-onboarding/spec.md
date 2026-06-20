# auth-onboarding

## Purpose

Route users after authentication and guide them through onboarding, with state
derived from data rather than a stored flag. Only the creator-profile step is
enforced; everything after it is offered through CTAs and redirects.

## Requirements

### Requirement: Post-authentication routing
The system SHALL route a user after sign-in and sign-up based on whether they have a creator profile. A user without a creator profile SHALL be sent to the creator profile form; a user with a creator profile SHALL be sent to the dashboard. Routing SHALL be implemented by overriding `after_sign_in_path_for` / `after_sign_up_path_for` rather than a global `before_action` wizard lock.

#### Scenario: New user without creator profile signs up
- **WHEN** a user completes sign-up and has no creator profile
- **THEN** the system redirects them to `new_creator_path`

#### Scenario: Existing user with creator profile signs in
- **WHEN** a user signs in and already has a creator profile
- **THEN** the system redirects them to `dashboard_path`

### Requirement: Onboarding state derived from data
The system SHALL derive onboarding state from existing records rather than from a stored flag. `User#onboarding_complete?` SHALL be true once the user has a creator profile and at least one idea, script, and LinkedIn post. `User#next_onboarding_step` SHALL return the first missing step in the order `:creator`, `:idea`, `:script`, `:post`, returning `:done` when all exist.

#### Scenario: User has only a creator profile
- **WHEN** `next_onboarding_step` is computed for a user with a creator profile and no ideas
- **THEN** it returns `:idea`

#### Scenario: User has completed every step
- **WHEN** a user has a creator profile, an idea, a script, and a LinkedIn post
- **THEN** `onboarding_complete?` returns true and `next_onboarding_step` returns `:done`

### Requirement: Guided but skippable onboarding
The system SHALL enforce only the creator-profile branch of onboarding. Every step after the creator profile SHALL be offered through CTAs and redirects, not gated. A user with a creator profile but no content SHALL still be able to reach other authenticated pages.

#### Scenario: Creator-but-no-content user navigates freely
- **WHEN** a user with a creator profile but no ideas visits an authenticated page such as `/chats`
- **THEN** the system allows access and does not force them back into a wizard
