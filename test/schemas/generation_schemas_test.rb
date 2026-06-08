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

  test "LinkedinPostSchema declares exactly the LinkedinPost generation fields" do
    assert_equal %i[title hook body], LinkedinPostSchema.properties.keys
  end

  test "TwitterPostSchema declares exactly the TwitterPost generation fields" do
    assert_equal %i[title hook body], TwitterPostSchema.properties.keys
  end

  test "InstagramPostSchema declares exactly the InstagramPost generation fields" do
    assert_equal %i[title hook body], InstagramPostSchema.properties.keys
  end

  test "schema fields mirror real columns on their model" do
    assert (IdeaSchema.properties.keys.map(&:to_s) - Idea.column_names).empty?,
           "IdeaSchema declares a field with no matching Idea column"
    assert (ScriptSchema.properties.keys.map(&:to_s) - Script.column_names).empty?,
           "ScriptSchema declares a field with no matching Script column"
    assert (LinkedinPostSchema.properties.keys.map(&:to_s) - LinkedinPost.column_names).empty?,
           "LinkedinPostSchema declares a field with no matching LinkedinPost column"
    assert (TwitterPostSchema.properties.keys.map(&:to_s) - TwitterPost.column_names).empty?,
           "TwitterPostSchema declares a field with no matching TwitterPost column"
    assert (InstagramPostSchema.properties.keys.map(&:to_s) - InstagramPost.column_names).empty?,
           "InstagramPostSchema declares a field with no matching InstagramPost column"
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
