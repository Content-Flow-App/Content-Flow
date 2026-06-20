# dashboard

## Purpose

The authenticated home surface: it renders the user's content chain (ideas →
scripts → LinkedIn posts) and an onboarding banner that reflects the next step.

## Requirements

### Requirement: Dashboard content
The system SHALL provide `DashboardController#show` that loads the user's creator profile and ideas with their scripts and LinkedIn posts (`current_user.ideas.includes(scripts: :linkedin_post)`) and renders the content chain on the dashboard.

#### Scenario: Dashboard shows the user's content chain
- **WHEN** an authenticated user visits the dashboard
- **THEN** the system renders their ideas with associated scripts and LinkedIn posts

### Requirement: Onboarding guidance banner
The system SHALL render an onboarding banner on the dashboard that reflects `next_onboarding_step`. While onboarding is incomplete the banner SHALL point to the next step; once onboarding is complete the banner SHALL be hidden or shown as complete.

#### Scenario: Incomplete onboarding shows the next step
- **WHEN** a user with a creator profile but no ideas views the dashboard
- **THEN** the onboarding banner indicates that the next step is to create an idea

#### Scenario: Completed onboarding hides the guidance
- **WHEN** a user who has completed every onboarding step views the dashboard
- **THEN** the onboarding banner is hidden or shown in its complete state
