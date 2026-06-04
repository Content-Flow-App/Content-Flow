# IdeaSchema is the structured-output contract for *generating* an Idea via the
# LLM. It is a RubyLLM::Schema subclass: the `string :field` DSL records each
# field (name, type, description, required) into the class, and `to_json_schema`
# renders it as the JSON Schema the model is told to fill in.
#
# Used on the generation path only — `chat.with_schema(IdeaSchema)` forces the
# response to come back as JSON matching these fields, which StructuredContent
# then maps onto an Idea record. Free-form refinement chats stay schema-less.
#
# The three fields mirror the `ideas` table columns (title/description/topic) so
# the parsed payload assigns cleanly onto the record.
class IdeaSchema < RubyLLM::Schema
  string :title, description: "A short, punchy title for the content idea."
  string :description, description: "One or two sentences explaining the idea and the angle to take."
  string :topic, description: "The subject area or theme the idea sits under (e.g. \"AI tooling\", \"career growth\")."
end
