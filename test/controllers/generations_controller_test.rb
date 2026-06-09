require "test_helper"

# Request specs for the generation engine. The LLM call is isolated by swapping
# StructuredExtraction.extract for a stub (its primary/fallback behavior is
# unit-tested separately and verified live by the F-3 spike), so these exercise
# the controller's flow: authorization, transcript building, persistence per
# purpose, and redirects — with no network.
#
# Minitest 6 dropped Object#stub, so we roll a tiny swap-and-restore helper.
class GenerationsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = User.create!(email: "gen@cf.test", password: "password123")
    Creator.create!(user: @user, name: "Ada", topic: "AI",
                    goal: "grow audience", audience: "founders")
    @idea = @user.ideas.create!(title: "Ship faster", topic: "AI",
                                description: "tips on shipping")
    @script = @idea.scripts.create!(title: "Draft", style: "educational",
                                    length: "short", description: "d", custom_instructions: "p")
    sign_in @user
  end

  # Replaces StructuredExtraction.extract for the block. `result` is returned as
  # the payload; pass a proc to raise instead (to simulate a failed extraction).
  def with_extraction(result)
    original = StructuredExtraction.method(:extract)
    StructuredExtraction.define_singleton_method(:extract) do |**kwargs|
      result.respond_to?(:call) ? result.call(**kwargs) : result
    end
    yield
  ensure
    StructuredExtraction.define_singleton_method(:extract, original)
  end

  # Builds a chat with a non-blank visible transcript so generation can proceed.
  def chat_with_transcript(owner, purpose)
    chat = owner.chats.create!(purpose: purpose)
    chat.messages.create!(role: "user", content: "Let's make something good.")
    chat.messages.create!(role: "assistant", content: "Sure — here's a strong draft.")
    chat
  end

  test "generate_idea creates an idea owned by the user and redirects to it" do
    chat = chat_with_transcript(@user, "generate_idea")
    payload = { "title" => "AI for founders", "description" => "A punchy angle.", "topic" => "AI tooling" }

    assert_difference -> { @user.ideas.count }, 1 do
      with_extraction(payload) { post chat_generation_path(chat) }
    end

    idea = @user.ideas.order(:created_at).last
    assert_equal "AI for founders", idea.title
    assert_equal "AI tooling", idea.topic
    assert_redirected_to idea_path(idea)
  end

  test "generate_script creates a script under the parent idea and redirects to it" do
    chat = chat_with_transcript(@idea, "generate_script")
    payload = { "title" => "How to ship", "description" => "the script body",
                "style" => "storytelling", "length" => "medium" }

    assert_difference -> { @idea.scripts.count }, 1 do
      with_extraction(payload) { post chat_generation_path(chat) }
    end

    script = @idea.scripts.order(:created_at).last
    assert_equal "How to ship", script.title
    assert_redirected_to script_path(script)
  end

  test "generate_linkedin_post builds the post on the script and redirects to it" do
    chat = chat_with_transcript(@script, "generate_linkedin_post")
    payload = { "title" => "Launch post", "hook" => "Stop scrolling.", "body" => "Here's why." }

    assert_difference -> { LinkedinPost.count }, 1 do
      with_extraction(payload) { post chat_generation_path(chat) }
    end

    assert_equal "Launch post", @script.reload.linkedin_post.title
    assert_redirected_to script_linkedin_post_path(@script)
  end

  test "generate_linkedin_post updates an existing post instead of creating a second" do
    @script.create_linkedin_post!(title: "old", hook: "old", body: "old")
    chat = chat_with_transcript(@script, "generate_linkedin_post")
    payload = { "title" => "fresh", "hook" => "new hook", "body" => "new body" }

    assert_no_difference -> { LinkedinPost.count } do
      with_extraction(payload) { post chat_generation_path(chat) }
    end

    assert_equal "fresh", @script.reload.linkedin_post.title
  end

  test "a non-owner gets 404 (owner re-resolved through a user-scoped relation)" do
    other = User.create!(email: "other@cf.test", password: "password123")
    other_idea = other.ideas.create!(title: "theirs", topic: "x", description: "d")
    # A chat whose chattable is someone else's idea — simulating a tampered request.
    chat = other_idea.chats.create!(purpose: "generate_script")
    chat.messages.create!(role: "user", content: "hi")

    with_extraction({ "title" => "x" }) { post chat_generation_path(chat) }

    assert_response :not_found
  end

  test "a missing chattable redirects back with an alert instead of 404ing" do
    chat = Chat.create!(purpose: "generate_script") # no chattable
    chat.messages.create!(role: "user", content: "hi")
    chat.messages.create!(role: "assistant", content: "sure")

    post chat_generation_path(chat)

    assert_redirected_to chat_path(chat)
    assert_match(/isn.t linked/i, flash[:alert])
  end

  test "an empty transcript redirects back to the chat with an alert" do
    chat = @user.chats.create!(purpose: "generate_idea") # no user/assistant messages

    assert_no_difference -> { Idea.count } do
      post chat_generation_path(chat)
    end

    assert_redirected_to chat_path(chat)
    assert_match(/before generating/i, flash[:alert])
  end

  test "an extraction failure redirects back to the chat with an alert, not a 500" do
    chat = chat_with_transcript(@user, "generate_idea")

    boom = ->(**) { raise StructuredExtraction::ExtractionFailed, "boom" }
    assert_no_difference -> { Idea.count } do
      with_extraction(boom) { post chat_generation_path(chat) }
    end

    assert_redirected_to chat_path(chat)
    assert_match(/failed/i, flash[:alert])
  end

  test "a validation failure (blank title) redirects back with the errors" do
    chat = chat_with_transcript(@user, "generate_idea")

    assert_no_difference -> { Idea.count } do
      with_extraction({ "description" => "no title here" }) { post chat_generation_path(chat) }
    end

    assert_redirected_to chat_path(chat)
    assert_match(/title/i, flash[:alert])
  end
end
