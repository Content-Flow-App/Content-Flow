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
The system SHALL derive onboarding state from existing records rather than from a stored flag. `User#onboarding_complete?` SHALL be true once the user has a creator profile, at least one idea, and at least one post. `User#next_onboarding_step` SHALL return the first unmet step in the order `:creator`, `:idea`, `:script`, `:post`, returning `:done` when complete. The `:script` step SHALL be **skippable**: it is surfaced as guidance toward the scripted flow when the user has an idea but no script and no post yet, but creating a post directly from an idea (the direct flow) SHALL complete onboarding without ever creating a script. The `:post` step SHALL be considered satisfied by **any** post the user owns, whether created through a script or directly from an idea.

#### Scenario: User has only a creator profile
- **WHEN** `next_onboarding_step` is computed for a user with a creator profile and no ideas
- **THEN** it returns `:idea`

#### Scenario: Script is suggested but not required
- **WHEN** a user has a creator profile and an idea but no script and no post
- **THEN** `next_onboarding_step` returns `:script` as guidance and `onboarding_complete?` returns false

#### Scenario: Direct post skips the script step and completes onboarding
- **WHEN** a user has a creator profile, an idea, and a post created directly from that idea (no script)
- **THEN** `onboarding_complete?` returns true and `next_onboarding_step` returns `:done`

#### Scenario: Scripted post completes onboarding
- **WHEN** a user has a creator profile, an idea, a script, and a post under that script
- **THEN** `onboarding_complete?` returns true and `next_onboarding_step` returns `:done`

### Requirement: Guided but skippable onboarding
The system SHALL enforce only the creator-profile branch of onboarding. Every step after the creator profile SHALL be offered through CTAs and redirects, not gated. A user with a creator profile but no content SHALL still be able to reach other authenticated pages.

#### Scenario: Creator-but-no-content user navigates freely
- **WHEN** a user with a creator profile but no ideas visits an authenticated page such as `/chats`
- **THEN** the system allows access and does not force them back into a wizard
