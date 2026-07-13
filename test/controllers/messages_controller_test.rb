require "test_helper"

class MessagesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = create_user!(email: "messages-create@cf.test")
    Creator.create!(user: @user, name: "Ada", topic: "AI",
                    goal: "grow audience", audience: "founders")
    @chat = @user.chats.create!
    sign_in @user
  end

  test "create persists the user's message and enqueues ChatResponseJob" do
    assert_enqueued_with(job: ChatResponseJob) do
      assert_difference -> { @chat.messages.count }, 1 do
        post chat_messages_path(@chat), params: { message: { content: "make it punchier" } }
      end
    end

    message = @chat.messages.order(:created_at).last
    assert_equal "user", message.role
    assert_equal "make it punchier", message.content
  end

  test "create responds with a turbo stream by default" do
    post chat_messages_path(@chat), params: { message: { content: "hi" } }, as: :turbo_stream

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html; charset=utf-8", response.media_type + "; charset=utf-8"
  end

  test "create redirects to the chat for an html request" do
    post chat_messages_path(@chat), params: { message: { content: "hi" } }

    assert_redirected_to @chat
  end

  # The `if content.present?` guard in MessagesController#create has no else
  # branch, so on blank/missing content `respond_to` never runs — Rails falls
  # through to implicit template lookup, finds no `messages/create.html.erb`
  # (only `create.turbo_stream.erb` exists), and returns a bare 406 rather
  # than a clean no-op. Documenting the actual response here rather than only
  # asserting the (correct) absence of side effects.
  test "create with blank content persists nothing, enqueues no job, and responds 406" do
    assert_no_enqueued_jobs do
      assert_no_difference -> { @chat.messages.count } do
        post chat_messages_path(@chat), params: { message: { content: "" } }
      end
    end

    assert_response :not_acceptable
  end

  test "create with no message param persists nothing, enqueues no job, and responds 406" do
    assert_no_enqueued_jobs do
      assert_no_difference -> { @chat.messages.count } do
        post chat_messages_path(@chat), params: {}
      end
    end

    assert_response :not_acceptable
  end
end
