## ADDED Requirements

### Requirement: Create and edit a creator profile
The system SHALL let an authenticated user create and edit a single creator profile capturing `name`, `topic`, `goal`, and `audience`. The controller SHALL permit parameters under the `:creator` key. After a successful create, the system SHALL redirect the user into the onboarding flow toward the next step.

#### Scenario: User creates a creator profile
- **WHEN** an authenticated user submits the creator form with valid name, topic, goal, and audience
- **THEN** the system persists the creator profile and redirects toward the next onboarding step

#### Scenario: Parameters are permitted under the creator key
- **WHEN** the creator form is submitted
- **THEN** the controller permits attributes under `params.require(:creator)` and not `:creators`

### Requirement: View a creator profile
The system SHALL implement `CreatorsController#show` and render the creator profile, displaying the stored name, topic, goal, and audience.

#### Scenario: User views their creator profile
- **WHEN** an authenticated user with a creator profile visits its show page
- **THEN** the system renders the stored name, topic, goal, and audience
