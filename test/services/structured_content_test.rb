require "test_helper"

class StructuredContentTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(email: "gen-owner@cf.test", password: "password123")
  end

  test "maps a parsed Hash payload (string keys) onto schema fields" do
    payload = { "title" => "Ship faster", "description" => "Tips on shipping", "topic" => "AI" }

    attrs = StructuredContent.attributes_for(IdeaSchema, payload)

    assert_equal({ title: "Ship faster", description: "Tips on shipping", topic: "AI" }, attrs)
  end

  test "accepts symbol-keyed Hash payloads too" do
    payload = { title: "Ship faster", description: "Tips", topic: "AI" }

    attrs = StructuredContent.attributes_for(IdeaSchema, payload)

    assert_equal "Ship faster", attrs[:title]
  end

  test "parses a raw JSON String payload (content_raw)" do
    payload = '{"title":"Hook them","description":"a punchy script","style":"educational","length":"short"}'

    attrs = StructuredContent.attributes_for(ScriptSchema, payload)

    assert_equal(
      { title: "Hook them", description: "a punchy script", style: "educational", length: "short" },
      attrs
    )
  end

  test "drops keys the schema does not declare" do
    payload = { "title" => "Ship faster", "description" => "x", "topic" => "AI",
                "id" => 999, "user_id" => 1, "evil" => "ignored" }

    attrs = StructuredContent.attributes_for(IdeaSchema, payload)

    assert_equal %i[title description topic], attrs.keys
  end

  test "omits fields missing from the payload rather than nil-ing them" do
    payload = { "title" => "Only a title" }

    attrs = StructuredContent.attributes_for(IdeaSchema, payload)

    assert_equal({ title: "Only a title" }, attrs)
  end

  test "assign writes the parsed attributes onto a record without saving" do
    idea = @user.ideas.build
    payload = { "title" => "Ship faster", "description" => "Tips", "topic" => "AI" }

    StructuredContent.assign(idea, IdeaSchema, payload)

    assert_equal "Ship faster", idea.title
    assert_equal "AI", idea.topic
    assert idea.new_record?, "assign should not persist the record"
  end

  test "raises InvalidPayload on a non-Hash, non-String payload" do
    assert_raises(StructuredContent::InvalidPayload) do
      StructuredContent.attributes_for(IdeaSchema, 42)
    end
  end

  test "raises InvalidPayload on malformed JSON" do
    assert_raises(StructuredContent::InvalidPayload) do
      StructuredContent.attributes_for(IdeaSchema, "{not json")
    end
  end
end
