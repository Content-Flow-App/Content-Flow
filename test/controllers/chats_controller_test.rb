require "test_helper"

class ChatsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = User.create!(email: "chat-create@cf.test", password: "password123")
    Creator.create!(user: @user, name: "Ada", topic: "AI",
                    goal: "grow audience", audience: "founders")
    @idea = @user.ideas.create!(title: "Ship faster", topic: "AI",
                                description: "tips on shipping")
    sign_in @user
  end

  test "create attaches the chattable and persists a creator-aware system message" do
    # The job only enqueues under the test adapter, so no LLM call fires —
    # the system instruction is persisted synchronously by with_instructions.
    assert_enqueued_with(job: ChatResponseJob) do
      post chats_path, params: {
        chat: {
          prompt: "Make this punchier",
          chattable_type: "Idea",
          chattable_id: @idea.id
        }
      }
    end

    chat = Chat.last
    assert_equal @idea, chat.chattable

    system_message = chat.messages.find_by(role: "system")
    assert system_message.present?, "expected a role: :system message"
    assert_includes system_message.content, "CREATOR PROFILE"
    assert_includes system_message.content, "PARENT IDEA"
    assert_includes system_message.content, "Ship faster"
  end

  test "create without a chattable leaves a standalone chat and no system message" do
    post chats_path, params: { chat: { prompt: "hello" } }

    chat = Chat.last
    assert_nil chat.chattable
    assert_nil chat.messages.find_by(role: "system")
  end

  test "create ignores a chattable_type outside the allowlist" do
    post chats_path, params: {
      chat: { prompt: "hi", chattable_type: "User", chattable_id: @user.id }
    }
    # User IS allowlisted; confirm a non-allowlisted type is rejected instead.
    post chats_path, params: {
      chat: { prompt: "hi", chattable_type: "Creator", chattable_id: @idea.id }
    }

    assert_nil Chat.last.chattable
  end
end
