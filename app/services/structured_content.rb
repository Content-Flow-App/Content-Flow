# StructuredContent bridges a schema-backed LLM response and an ActiveRecord
# record. On the generation path the chat is asked with `with_schema(IdeaSchema)`
# (or ScriptSchema); ruby_llm then returns/persists the answer as JSON. This
# service takes that payload — the assistant message's parsed `content` (a Hash)
# or the raw `content_raw` JSON (a String) — and produces the attributes to
# assign onto an Idea/Script record.
#
# The schema is the allow-list: only fields the schema *declares*
# (`schema.properties.keys`) are written. So even if the model returns extra
# keys, they are dropped — the LLM can never set an attribute the schema didn't
# ask for. Pairing is by design: IdeaSchema -> Idea, ScriptSchema -> Script.
#
# Usage (future generation path, once wired):
#   response = chat.with_schema(IdeaSchema).ask("Generate an idea about ...")
#   StructuredContent.assign(idea, IdeaSchema, response.content)
#   idea.save
class StructuredContent
  # Raised when the payload is neither a Hash nor parseable JSON. We fail loud
  # rather than silently writing nothing — a malformed generation should surface.
  class InvalidPayload < StandardError; end

  def self.attributes_for(schema, payload)
    new(schema, payload).attributes
  end

  # Assigns the parsed attributes onto `record` (without saving) and returns it,
  # so callers can validate/save on their own terms.
  def self.assign(record, schema, payload)
    record.assign_attributes(attributes_for(schema, payload))
    record
  end

  def initialize(schema, payload)
    @schema = schema
    @payload = payload
  end

  # A Hash of { field => value } limited to the schema's declared fields and to
  # keys actually present in the payload (so a missing field leaves the record's
  # existing value untouched rather than nil-ing it).
  def attributes
    data = coerce_to_hash(@payload)

    @schema.properties.keys.each_with_object({}) do |field, attrs|
      key = field.to_s
      attrs[field] = data[key] if data.key?(key)
    end
  end

  private

  # Normalizes the payload to a String-keyed Hash. Accepts an already-parsed
  # Hash (ruby_llm parses schema responses into `message.content`) or the raw
  # JSON String (`message.content_raw`).
  def coerce_to_hash(payload)
    case payload
    when Hash   then payload.transform_keys(&:to_s)
    when String then JSON.parse(payload)
    else raise InvalidPayload, "expected a Hash or JSON String, got #{payload.class}"
    end
  rescue JSON::ParserError => e
    raise InvalidPayload, "could not parse JSON payload: #{e.message}"
  end
end
