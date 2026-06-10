# ScriptSchema is the structured-output contract for *generating* a Script via
# the LLM. Like IdeaSchema, it is a RubyLLM::Schema subclass whose `string`
# declarations become the JSON Schema handed to the model through
# `chat.with_schema(ScriptSchema)`.
#
# The four fields mirror the `scripts` table columns that hold generated content
# (title/description/style/length). `custom_instructions` is intentionally
# excluded: it is creator/app-supplied context fed *into* generation (see
# LlmContext), not something the model fills in.
class ScriptSchema < RubyLLM::Schema
  string :title, max_length: 50, description: "A punchy title, maximum 4-5 words. No subtitles, no colons, no years. It will be displayed very large — keep it poster-short. Examples: \"AI Kills Your Job\", \"Stop Faking Productivity\", \"Your Attention Is Gone\"."
  string :description, description: "The script content itself — the full draft the creator will record or post."
  string :style, description: "The tone or format of the script (e.g. \"educational\", \"storytelling\", \"listicle\")."
  string :length, description: "The intended length bucket: \"short\", \"medium\", or \"long\"."
end
