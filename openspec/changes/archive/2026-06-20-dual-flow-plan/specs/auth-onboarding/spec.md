## MODIFIED Requirements

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
