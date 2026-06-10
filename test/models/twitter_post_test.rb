require "test_helper"

class TwitterPostTest < ActiveSupport::TestCase
  def setup
    @user   = User.create!(email: "twitter-model@cf.test", password: "password123")
    @idea   = @user.ideas.create!(title: "Ship faster", topic: "AI", description: "tips")
    @script = @idea.scripts.create!(title: "s", style: "educational",
                                    length: "short", description: "d", custom_instructions: "p")
  end

  test "valid with a title and a script" do
    post = @script.build_twitter_post(title: "My thread")
    assert post.valid?
  end

  test "requires a title" do
    post = @script.build_twitter_post(title: nil)
    assert_not post.valid?
    assert_includes post.errors[:title], "can't be blank"
  end

  test "requires exactly one parent (neither script nor idea is an orphan)" do
    post = TwitterPost.new(title: "Orphan")
    assert_not post.valid?
    assert_includes post.errors[:base], "must belong to either a script or an idea, not both"
  end

  test "requires exactly one parent (both script and idea is invalid)" do
    post = TwitterPost.new(title: "Ambiguous", script: @script, idea: @idea)
    assert_not post.valid?
    assert_includes post.errors[:base], "must belong to either a script or an idea, not both"
  end

  test "valid with a title and a direct idea" do
    post = @idea.build_twitter_post(title: "Direct thread")
    assert post.valid?
  end

  test "reaches the owning user through its idea (direct path)" do
    post = @idea.create_twitter_post!(title: "Direct thread")
    assert_equal @user, post.user
  end

  test "is destroyed with its idea (direct path)" do
    @idea.create_twitter_post!(title: "Doomed")
    assert_difference("TwitterPost.count", -1) { @idea.destroy }
  end

  test "enforces one twitter post per script" do
    @script.create_twitter_post!(title: "First")
    dup = TwitterPost.new(script: @script, title: "Second")
    assert_not dup.valid?
    assert_includes dup.errors[:script_id], "has already been taken"
  end

  test "reaches the owning user through its script" do
    post = @script.create_twitter_post!(title: "My thread")
    assert_equal @user, post.user
  end

  test "is destroyed with its script" do
    @script.create_twitter_post!(title: "Doomed")
    assert_difference("TwitterPost.count", -1) { @script.destroy }
  end

  test "owns chats via the polymorphic chattable association" do
    post = @script.create_twitter_post!(title: "My thread")
    chat = post.chats.create!

    assert_equal post, chat.chattable
    assert_equal "TwitterPost", chat.chattable_type
    assert_includes post.chats, chat
  end

  test "its chats are destroyed with it" do
    post = @script.create_twitter_post!(title: "Doomed")
    post.chats.create!

    assert_difference("Chat.count", -1) { post.destroy }
  end
end
