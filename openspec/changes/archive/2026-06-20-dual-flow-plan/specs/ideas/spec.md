## ADDED Requirements

### Requirement: Idea show page links to direct posts
The system SHALL show, on an idea's detail page, a "posts" section listing the posts created directly from that idea (alongside the existing scripts section), and SHALL offer both a "write a script" call to action (scripted flow) and a "create a post directly" call to action (direct flow). The direct CTA SHALL target the new idea-nested post for that idea.

#### Scenario: Idea detail page offers both creation paths
- **WHEN** an authenticated user views one of their ideas
- **THEN** the page shows a "write a script" CTA targeting the new-script form and a "create a post directly" CTA targeting the new idea-nested post

#### Scenario: Direct posts are listed on the idea
- **WHEN** an idea has one or more posts created directly from it
- **THEN** the idea show page lists those posts in a "posts" section with a link to each
