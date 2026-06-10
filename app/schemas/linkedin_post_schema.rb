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
  string :title,
         description: "A short, descriptive title for the LinkedIn post (internal label, not necessarily shown in the post)."
  string :hook, description: "The opening line or two — the scroll-stopping hook that makes a reader expand the post."
  string :body, description: "The full body following the hook. Use short paragraphs separated by blank lines — one idea per paragraph. Front-load the key insight in the first ~200 characters (all that shows before ‘See more’). Aim for 300-500 words. Close with a question or discussion prompt and 3-5 relevant hashtags on their own line."
end
