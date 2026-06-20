require "test_helper"

class ChatTest < ActiveSupport::TestCase
  def setup
    @user = create_user!(email: "chat-owner@cf.test")
  end

  test "a chat can belong to a polymorphic chattable owner" do
    chat = @user.chats.create!

    assert_equal @user, chat.chattable
    assert_equal "User", chat.chattable_type
    assert_equal @user.id, chat.chattable_id
    assert_includes @user.chats, chat
  end

  test "a chat is valid with no owner (optional polymorphic association)" do
    chat = Chat.new

    assert chat.valid?, "standalone chats must remain valid for the existing /chats flow"
    assert_nil chat.chattable
  end

  test "ideas, scripts, and linkedin posts each own chats via chattable" do
    idea   = @user.ideas.create!(title: "t", topic: "ai", description: "d")
    script = Script.create!(idea: idea, title: "s", style: "educational",
                            length: "short", description: "d", custom_instructions: "p")
    post   = LinkedinPost.create!(script: script, title: "p", hook: "h", body: "b")

    [ idea, script, post ].each do |owner|
      chat = owner.chats.create!
      assert_equal owner, chat.chattable
      assert_includes owner.chats, chat
    end
  end

  test "destroying an owner destroys its chats" do
    idea = @user.ideas.create!(title: "t", topic: "ai", description: "d")
    idea.chats.create!

    assert_difference -> { Chat.count }, -1 do
      idea.destroy
    end
  end

  test "purpose persists and exposes a predicate + scope" do
    chat = @user.chats.create!(purpose: "generate_idea")

    assert_equal "generate_idea", chat.reload.purpose
    assert chat.generate_idea?
    assert_includes Chat.generate_idea, chat
  end

  test "a nil purpose is valid (plain free-form chat)" do
    chat = Chat.new

    assert chat.valid?
    assert_nil chat.purpose
  end

  test "an unknown purpose is a validation error, not a raised ArgumentError" do
    chat = Chat.new(purpose: "bogus")

    assert_not chat.valid?
    assert_includes chat.errors[:purpose], "is not included in the list"
  end
end
