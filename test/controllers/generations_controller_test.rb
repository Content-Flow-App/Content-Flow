require "test_helper"

# Request specs for the generation endpoint. The slow LLM extraction now runs
# in GenerationJob (covered in test/jobs/generation_job_test.rb), so these
# exercise what remains in the request: authorization, the guards, the
# enqueue, and the immediate loading-state response.
class GenerationsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  # assert_enqueued_with / assert_no_enqueued_jobs come from Active Job's test
  # helper; the test adapter records enqueued jobs instead of running them.
  include ActiveJob::TestHelper

  def setup
    @user = create_user!(email: "gen@cf.test")
    Creator.create!(user: @user, name: "Ada", topic: "AI",
                    goal: "grow audience", audience: "founders")
    @idea = @user.ideas.create!(title: "Ship faster", topic: "AI",
                                description: "tips on shipping")
    sign_in @user
  end

  # Builds a chat with a non-blank visible transcript so generation can proceed.
  def chat_with_transcript(owner, purpose)
    chat = owner.chats.create!(purpose: purpose)
    chat.messages.create!(role: "user", content: "Let's make something good.")
    chat.messages.create!(role: "assistant", content: "Sure — here's a strong draft.")
    chat
  end

  test "create enqueues a GenerationJob for the chat and current user" do
    chat = chat_with_transcript(@user, "generate_idea")

    assert_enqueued_with(job: GenerationJob, args: [chat.id, @user.id]) do
      post chat_generation_path(chat)
    end
  end

  test "no record is created in the request — the job does the saving" do
    chat = chat_with_transcript(@user, "generate_idea")

    assert_no_difference -> { Idea.count } do
      post chat_generation_path(chat)
    end
  end

  test "a turbo stream request gets the loading state replacing the save button" do
    chat = chat_with_transcript(@user, "generate_idea")

    post chat_generation_path(chat), as: :turbo_stream

    assert_response :success
    assert_match "generation-action", response.body
    assert_match(/cece is cooking/i, response.body)
  end

  test "a plain html request falls back to a redirect with a notice" do
    chat = chat_with_transcript(@user, "generate_idea")

    post chat_generation_path(chat)

    assert_redirected_to chat_path(chat)
    assert_match(/saving/i, flash[:notice])
  end

  test "a non-owner gets 404 and no job is enqueued" do
    other = create_user!(email: "other@cf.test")
    other_idea = other.ideas.create!(title: "theirs", topic: "x", description: "d")
    # A chat whose chattable is someone else's idea — simulating a tampered request.
    chat = other_idea.chats.create!(purpose: "generate_script")
    chat.messages.create!(role: "user", content: "hi")

    assert_no_enqueued_jobs(only: GenerationJob) do
      post chat_generation_path(chat)
    end

    assert_response :not_found
  end

  test "a missing chattable redirects back with an alert and enqueues nothing" do
    chat = Chat.create!(purpose: "generate_script") # no chattable
    chat.messages.create!(role: "user", content: "hi")
    chat.messages.create!(role: "assistant", content: "sure")

    assert_no_enqueued_jobs(only: GenerationJob) do
      post chat_generation_path(chat)
    end

    assert_redirected_to chat_path(chat)
    assert_match(/isn.t linked/i, flash[:alert])
  end

  test "an empty transcript redirects back to the chat and enqueues nothing" do
    chat = @user.chats.create!(purpose: "generate_idea") # no user/assistant messages

    assert_no_enqueued_jobs(only: GenerationJob) do
      post chat_generation_path(chat)
    end

    assert_redirected_to chat_path(chat)
    assert_match(/before generating/i, flash[:alert])
  end
end
