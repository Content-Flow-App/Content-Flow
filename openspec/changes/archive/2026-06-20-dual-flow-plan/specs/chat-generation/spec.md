## MODIFIED Requirements

### Requirement: Generate content via chat
The system SHALL turn each content `new` action (idea, script, LinkedIn post) into a redirect to the chat composer carrying a `purpose` and the chattable context, so the user generates the record by conversation rather than a blank form. The redirect targets SHALL be `generate_idea` (context `User`), `generate_script` (context `Idea`), and `generate_linkedin_post`. For `generate_linkedin_post` the chattable context SHALL be whichever parent the `new` action was reached through — the `Script` (scripted flow) or the `Idea` (direct flow).

#### Scenario: New idea redirects into a generation chat
- **WHEN** an authenticated user triggers `ideas#new`
- **THEN** the system redirects to the chat composer with `purpose=generate_idea` and the current user as the chattable context

#### Scenario: New script carries its parent idea
- **WHEN** an authenticated user triggers `scripts#new` for an idea
- **THEN** the system redirects to the chat composer with `purpose=generate_script` and that idea as the chattable context

#### Scenario: Direct post generation carries its parent idea
- **WHEN** an authenticated user triggers the LinkedIn post `new` action nested under an idea
- **THEN** the system redirects to the chat composer with `purpose=generate_linkedin_post` and that idea as the chattable context

#### Scenario: Scripted post generation carries its parent script
- **WHEN** an authenticated user triggers the LinkedIn post `new` action nested under a script
- **THEN** the system redirects to the chat composer with `purpose=generate_linkedin_post` and that script as the chattable context

### Requirement: Purpose discriminates the generation target
The system SHALL store a `purpose` on the chat to disambiguate intent, since chattable type alone is ambiguous. MVP values SHALL be `generate_idea`, `generate_script`, and `generate_linkedin_post`; a nil purpose SHALL mean a plain free-form chat. The purpose SHALL determine the extraction schema, the owner resolution, the persistence target, and the post-save redirect. For `generate_linkedin_post` the chattable type SHALL further select the branch: a `Script` chattable resolves through `current_user_scripts.find`, persists via `script.build_linkedin_post.save`, and redirects to `script_linkedin_post_path`; an `Idea` chattable resolves through `current_user.ideas.find`, persists via `idea.linkedin_posts.create`, and redirects to `idea_linkedin_post_path`. Both branches use `LinkedinPostSchema`.

#### Scenario: Purpose selects schema and persistence
- **WHEN** a generation runs for a chat whose purpose is `generate_script`
- **THEN** the system uses `ScriptSchema`, resolves the owning idea through `current_user.ideas.find`, creates the script on that idea, and redirects to the script

#### Scenario: Nil purpose leaves the chat free-form
- **WHEN** a chat has no purpose
- **THEN** the system treats it as a plain conversation with no generation behavior

#### Scenario: Scripted post generation persists under the script
- **WHEN** a `generate_linkedin_post` generation runs with a `Script` chattable
- **THEN** the system uses `LinkedinPostSchema`, builds the post via `script.build_linkedin_post`, and redirects to `script_linkedin_post_path`

#### Scenario: Direct post generation persists under the idea
- **WHEN** a `generate_linkedin_post` generation runs with an `Idea` chattable
- **THEN** the system uses `LinkedinPostSchema`, creates the post via `idea.linkedin_posts.create`, and redirects to `idea_linkedin_post_path`
