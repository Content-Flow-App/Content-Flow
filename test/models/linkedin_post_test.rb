require "test_helper"

class LinkedinPostTest < ActiveSupport::TestCase
  def setup
    @user   = create_user!(email: "linkedin-model@cf.test")
    @idea   = @user.ideas.create!(title: "Ship faster", topic: "AI", description: "tips")
    @script = @idea.scripts.create!(title: "s", style: "educational",
                                    length: "short", description: "d", custom_instructions: "p")
  end

  test "requires exactly one parent (neither script nor idea is an orphan)" do
    post = LinkedinPost.new(title: "Orphan")
    assert_not post.valid?
    assert_includes post.errors[:base], "must belong to either a script or an idea, not both"
  end

  test "requires exactly one parent (both script and idea is invalid)" do
    post = LinkedinPost.new(title: "Ambiguous", script: @script, idea: @idea)
    assert_not post.valid?
    assert_includes post.errors[:base], "must belong to either a script or an idea, not both"
  end

  test "reaches the owning user through its script" do
    post = @script.create_linkedin_post!(title: "My post")
    assert_equal @user, post.user
  end

  test "reaches the owning user through its idea (direct path)" do
    post = @idea.create_linkedin_post!(title: "Direct post")
    assert_equal @user, post.user
  end

  test "is destroyed with its idea (direct path)" do
    @idea.create_linkedin_post!(title: "Doomed")
    assert_difference("LinkedinPost.count", -1) { @idea.destroy }
  end

  test "owns chats via the polymorphic chattable association" do
    post = @script.create_linkedin_post!(title: "My post")
    chat = post.chats.create!(user: post.user)

    assert_equal post, chat.chattable
    assert_equal "LinkedinPost", chat.chattable_type
    assert_includes post.chats, chat
  end

  test "its chats are destroyed with it" do
    post = @script.create_linkedin_post!(title: "Doomed")
    post.chats.create!(user: post.user)

    assert_difference("Chat.count", -1) { post.destroy }
  end
end
