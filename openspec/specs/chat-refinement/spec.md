# chat-refinement

## Purpose

Refine an existing record by conversation: a "refine with ai" CTA on each show
page opens a chat attached to that record, and an "apply changes" action updates
the same record from a structured extraction. Manual CRUD forms stay intact and
no `purpose` column is added.

## Requirements

### Requirement: Open a refinement chat from a show page
The system SHALL render a "refine with ai" call to action on the idea, script, and LinkedIn post show pages that opens a chat attached to that record via `chattable`. The chat form SHALL carry hidden `chat[chattable_type]` and `chat[chattable_id]` fields, and `ChatsController#new` SHALL seed `@chat` from allowlisted chattable params. This track SHALL NOT add a `purpose` column and SHALL leave the manual CRUD forms unchanged.

#### Scenario: User opens a refine chat for an idea
- **WHEN** an authenticated user clicks "refine with ai" on an idea show page
- **THEN** the system opens a chat whose chattable is that idea, seeded from the hidden chattable fields

#### Scenario: Chattable type alone selects the schema
- **WHEN** a refinement runs on a chat attached to a Script
- **THEN** the system selects `ScriptSchema` from the chattable type without consulting any purpose field

### Requirement: Apply AI changes back onto the record
The system SHALL render a conditional "apply changes to this idea / script / post" action on the chat show page, gated on the chattable being an Idea, Script, or LinkedinPost and on visible messages existing. Applying SHALL run a one-shot structured extraction on a transient chat (keeping the visible transcript clean) and SHALL always `update` the chattable, then redirect to its show page. The system SHALL authorize by re-resolving the chattable through user-scoped relations (`current_user.ideas.find`, `current_user_scripts.find`, `current_user_linkedin_posts.find`) and SHALL never trust `chat.chattable`.

#### Scenario: User applies refinements to a script
- **WHEN** an authenticated user clicks "apply changes" on a script refinement chat with visible messages
- **THEN** the system extracts the improved fields, updates that script, and redirects to the script show page

#### Scenario: Apply button hidden without a refinable target
- **WHEN** a chat has no chattable of a refinable type, or has no visible messages
- **THEN** the apply button is not shown

#### Scenario: Non-owner is blocked from applying
- **WHEN** a user attempts to apply changes to a record they do not own
- **THEN** the user-scoped `.find` raises and the request is blocked (404)

### Requirement: Refinement preserves undiscussed fields
The system SHALL instruct the transient extraction that the conversation refines the existing record and SHALL output every field, returning the current value unchanged for any field the conversation did not discuss. This overwrite-all-keep-undiscussed behavior SHALL prevent the model from echoing or blanking fields that were not part of the discussion.

#### Scenario: Undiscussed field retains its current value
- **WHEN** a refinement conversation only changes a record's title
- **THEN** the applied update keeps the other fields at their current values
