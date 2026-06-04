require "test_helper"

# Contract tests for the generation schemas. These guard against drift: if a
# field is added/removed/renamed here it should be a deliberate change matched
# against the corresponding table columns, not an accident.
class GenerationSchemasTest < ActiveSupport::TestCase
  test "IdeaSchema declares exactly the Idea generation fields" do
    assert_equal %i[title description topic], IdeaSchema.properties.keys
  end

  test "ScriptSchema declares exactly the Script generation fields" do
    assert_equal %i[title description style length], ScriptSchema.properties.keys
  end

  test "schema fields mirror real columns on their model" do
    assert (IdeaSchema.properties.keys.map(&:to_s) - Idea.column_names).empty?,
           "IdeaSchema declares a field with no matching Idea column"
    assert (ScriptSchema.properties.keys.map(&:to_s) - Script.column_names).empty?,
           "ScriptSchema declares a field with no matching Script column"
  end

  test "to_json_schema renders typed string properties the model can fill" do
    schema = IdeaSchema.new.to_json_schema

    # ruby_llm wraps the JSON Schema; the property definitions live under
    # schema[:schema][:properties]. Each declared field is a typed string.
    properties = schema.dig(:schema, :properties)
    assert_equal %w[title description topic], properties.keys.map(&:to_s)
    assert_equal "string", properties[:title][:type]
    assert properties[:title][:description].present?
  end
end
