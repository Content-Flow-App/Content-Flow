# ScriptSchema is the structured-output contract for *generating* a Script via
# the LLM. Like IdeaSchema, it is a RubyLLM::Schema subclass whose `string`
# declarations become the JSON Schema handed to the model through
# `chat.with_schema(ScriptSchema)`.
#
# The four fields mirror the `scripts` table columns that hold generated content
# (title/description/style/length). `system_prompt` is intentionally excluded:
# it is creator/app-supplied context fed *into* generation (see LlmContext), not
# something the model fills in.
class ScriptSchema < RubyLLM::Schema
  string :title, description: "A short, descriptive title for the script."
  string :description, description: "The script content itself — the full draft the creator will record or post."
  string :style, description: "The tone or format of the script (e.g. \"educational\", \"storytelling\", \"listicle\")."
  string :length, description: "The intended length bucket: \"short\", \"medium\", or \"long\"."
end
