# LinkedinPostSchema is the structured-output contract for *generating* a
# LinkedinPost via the LLM. Like IdeaSchema and ScriptSchema, it is a
# RubyLLM::Schema subclass whose `string` declarations become the JSON Schema
# handed to the model through `chat.with_schema(LinkedinPostSchema)`.
#
# The three fields mirror the `linkedin_posts` table columns that hold generated
# content (title/hook/body). `script_id` is intentionally excluded: it is the
# parent association set by the controller (`@script.build_linkedin_post`), not
# something the model fills in.
class LinkedinPostSchema < RubyLLM::Schema
  string :title, description: "A short, descriptive title for the LinkedIn post (internal label, not necessarily shown in the post)."
  string :hook, description: "The opening line or two — the scroll-stopping hook that makes a reader expand the post."
  string :body, description: "The full body of the LinkedIn post following the hook, formatted and ready to publish. Front-load your ideas: Treat the first 210 characters like a newspaper headline to compel readers to click ‘See more’. character post limit is 400–500 words"
end
