require "test_helper"
require "turbo/broadcastable/test_helper"

# The background half of "save as ...": extraction, persistence, and the
# Turbo Stream broadcasts the user actually sees. The LLM call is isolated by
# swapping StructuredExtraction.extract for a stub (its primary/fallback
# behavior is unit-tested separately), so these run with no network.
class GenerationJobTest < ActiveJob::TestCase
  # capture_turbo_stream_broadcasts records the <turbo-stream> elements the job
  # pushes over Action Cable so we can assert on what reaches the chat page.
  include Turbo::Broadcastable::TestHelper
  # Path helpers, to assert the broadcast redirect points at the right record.
  include Rails.application.routes.url_helpers

  def setup
    @user = create_user!(email: "genjob@cf.test")
    Creator.create!(user: @user, name: "Ada", topic: "AI",
                    goal: "grow audience", audience: "founders")
    @idea = @user.ideas.create!(title: "Ship faster", topic: "AI",
                                description: "tips on shipping")
    @script = @idea.scripts.create!(title: "Draft", style: "educational",
                                    length: "short", description: "d", custom_instructions: "p")
  end

  # Replaces StructuredExtraction.extract for the block. `result` is returned as
  # the payload; pass a proc to raise instead (to simulate a failed extraction).
  # Minitest 6 dropped Object#stub, so we roll a tiny swap-and-restore helper.
  def with_extraction(result)
    original = StructuredExtraction.method(:extract)
    StructuredExtraction.define_singleton_method(:extract) do |**kwargs|
      result.respond_to?(:call) ? result.call(**kwargs) : result
    end
    yield
  ensure
    StructuredExtraction.define_singleton_method(:extract, original)
  end

  def chat_with_transcript(owner, purpose)
    chat = owner.chats.create!(purpose: purpose, user: owner.is_a?(User) ? owner : owner.user)
    chat.messages.create!(role: "user", content: "Let's make something good.")
    chat.messages.create!(role: "assistant", content: "Sure — here's a strong draft.")
    chat
  end

  # Runs the job with extraction stubbed and returns the broadcast elements.
  def perform_with_extraction(chat, payload, user: @user)
    elements = nil
    with_extraction(payload) do
      elements = capture_turbo_stream_broadcasts("chat_#{chat.id}") do
        GenerationJob.perform_now(chat.id, user.id)
      end
    end
    elements
  end

  test "generate_idea saves the idea and broadcasts a redirect to it" do
    chat = chat_with_transcript(@user, "generate_idea")
    payload = { "title" => "AI for founders", "description" => "A punchy angle.", "topic" => "AI tooling" }

    elements = nil
    assert_difference -> { @user.ideas.count }, 1 do
      elements = perform_with_extraction(chat, payload)
    end

    idea = @user.ideas.order(:created_at).last
    assert_equal "AI for founders", idea.title
    assert_equal "AI tooling", idea.topic

    html = elements.map(&:to_html).join
    assert_includes html, 'data-controller="redirect"'
    assert_includes html, idea_path(idea)
  end

  test "generate_script saves the script under the parent idea" do
    chat = chat_with_transcript(@idea, "generate_script")
    payload = { "title" => "How to ship", "description" => "the script body",
                "style" => "storytelling", "length" => "medium" }

    elements = nil
    assert_difference -> { @idea.scripts.count }, 1 do
      elements = perform_with_extraction(chat, payload)
    end

    script = @idea.scripts.order(:created_at).last
    assert_equal "How to ship", script.title
    assert_includes elements.map(&:to_html).join, script_path(script)
  end

  test "generate_linkedin_post builds the post on the script" do
    chat = chat_with_transcript(@script, "generate_linkedin_post")
    payload = { "title" => "Launch post", "hook" => "Stop scrolling.", "body" => "Here's why." }

    assert_difference -> { LinkedinPost.count }, 1 do
      perform_with_extraction(chat, payload)
    end

    assert_equal "Launch post", @script.reload.linkedin_post.title
  end

  test "generate_linkedin_post updates an existing post instead of creating a second" do
    @script.create_linkedin_post!(title: "old", hook: "old", body: "old")
    chat = chat_with_transcript(@script, "generate_linkedin_post")
    payload = { "title" => "fresh", "hook" => "new hook", "body" => "new body" }

    assert_no_difference -> { LinkedinPost.count } do
      perform_with_extraction(chat, payload)
    end

    assert_equal "fresh", @script.reload.linkedin_post.title
  end

  test "an extraction failure broadcasts an error and restores the save button" do
    chat = chat_with_transcript(@user, "generate_idea")
    boom = ->(**) { raise StructuredExtraction::ExtractionFailed, "boom" }

    elements = nil
    assert_no_difference -> { Idea.count } do
      assert_nothing_raised { elements = perform_with_extraction(chat, boom) }
    end

    html = elements.map(&:to_html).join
    assert_includes html, "save failed"
    # The button comes back so the user can retry — never a permanent spinner.
    assert_includes elements.map { |el| el["target"] }, "generation-action"
  end

  test "a validation failure broadcasts the errors instead of dying" do
    chat = chat_with_transcript(@user, "generate_idea")

    elements = nil
    assert_no_difference -> { Idea.count } do
      elements = perform_with_extraction(chat, { "description" => "no title here" })
    end

    html = elements.map(&:to_html).join
    assert_match(/title/i, html)
    assert_includes elements.map { |el| el["target"] }, "generation-action"
  end

  test "a non-owner's chat broadcasts a failure and saves nothing" do
    other = create_user!(email: "otherjob@cf.test")
    other_idea = other.ideas.create!(title: "theirs", topic: "x", description: "d")
    chat = chat_with_transcript(other_idea, "generate_script")

    elements = nil
    assert_no_difference -> { Script.count } do
      # The user-scoped find raises RecordNotFound; the job rescues it rather
      # than dying (a job can't return a 404 — the controller already did).
      assert_nothing_raised do
        elements = perform_with_extraction(chat, { "title" => "x" }, user: @user)
      end
    end

    assert_includes elements.map(&:to_html).join, "save failed"
  end
end
