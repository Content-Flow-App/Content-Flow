require "test_helper"

class ChatTest < ActiveSupport::TestCase
  def setup
    @user = create_user!(email: "chat-owner@cf.test")
  end

  test "a chat can belong to a polymorphic chattable owner" do
    chat = @user.chats.create!(user: @user)

    assert_equal @user, chat.chattable
    assert_equal "User", chat.chattable_type
    assert_equal @user.id, chat.chattable_id
    assert_includes @user.chats, chat
  end

  test "a chat is valid with no chattable, as long as it has a user (standalone chat)" do
    chat = Chat.new(user: @user)

    assert chat.valid?, "standalone chats must remain valid for the existing /chats flow"
    assert_nil chat.chattable
  end

  test "ideas, scripts, and linkedin posts each own chats via chattable" do
    idea   = @user.ideas.create!(title: "t", topic: "ai", description: "d")
    script = Script.create!(idea: idea, title: "s", style: "educational",
                            length: "short", description: "d", custom_instructions: "p")
    post   = LinkedinPost.create!(script: script, title: "p", hook: "h", body: "b")

    [ idea, script, post ].each do |owner|
      chat = owner.chats.create!(user: owner.user)
      assert_equal owner, chat.chattable
      assert_includes owner.chats, chat
    end
  end

  test "destroying an owner destroys its chats" do
    idea = @user.ideas.create!(title: "t", topic: "ai", description: "d")
    idea.chats.create!(user: idea.user)

    assert_difference -> { Chat.count }, -1 do
      idea.destroy
    end
  end

  test "purpose persists and exposes a predicate + scope" do
    chat = @user.chats.create!(purpose: "generate_idea", user: @user)

    assert_equal "generate_idea", chat.reload.purpose
    assert chat.generate_idea?
    assert_includes Chat.generate_idea, chat
  end

  test "a nil purpose is valid (plain free-form chat)" do
    chat = Chat.new(user: @user)

    assert chat.valid?
    assert_nil chat.purpose
  end

  test "an unknown purpose is a validation error, not a raised ArgumentError" do
    chat = Chat.new(purpose: "bogus")

    assert_not chat.valid?
    assert_includes chat.errors[:purpose], "is not included in the list"
  end

  # ── direct ownership (user_id) — see issue #27 ────────────────────────────

  test "a chat without a user is invalid" do
    chat = Chat.new(chattable: @user)

    assert_not chat.valid?
    assert_includes chat.errors[:user], "must exist"
  end

  test "User#owned_chats is scoped by user_id and is distinct from User#chats" do
    standalone = Chat.create!(user: @user) # no chattable at all
    direct     = @user.chats.create!(user: @user) # chattable = @user too

    assert_includes @user.owned_chats, standalone
    assert_includes @user.owned_chats, direct

    assert_includes @user.chats, direct
    assert_not_includes @user.chats, standalone, "a standalone chat has no chattable, so it can't appear in the chattable-based #chats relation even though it's owned"
  end

  # ── model resolution ──────────────────────────────────────────────────────
  # acts_as_chat resolves the model on save (resolve_model_from_strings); a
  # chat created with no explicit model falls back to RubyLLM.config.default_model,
  # and an explicit model wins over that default. Nothing exercised this
  # directly before — see test/config/ruby_llm_registry_test.rb for the
  # lower-level registry guard.

  test "a chat with no explicit model resolves to the configured default" do
    chat = @user.chats.create!(user: @user)

    assert_equal "claude-sonnet-5", chat.model_id
    assert_equal "anthropic", chat.provider
  end

  test "a chat created with an explicit model honors it over the default" do
    chat = @user.chats.create!(model: "gpt-4o-mini", user: @user)

    assert_equal "gpt-4o-mini", chat.model_id
    assert_equal "openai", chat.provider
  end
end
