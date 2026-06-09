require "test_helper"

class InstagramPostTest < ActiveSupport::TestCase
  def setup
    @user   = User.create!(email: "instagram-model@cf.test", password: "password123")
    @idea   = @user.ideas.create!(title: "Ship faster", topic: "AI", description: "tips")
    @script = @idea.scripts.create!(title: "s", style: "educational",
                                    length: "short", description: "d", custom_instructions: "p")
  end

  test "valid with a title and a script" do
    post = @script.build_instagram_post(title: "My caption")
    assert post.valid?
  end

  test "requires a title" do
    post = @script.build_instagram_post(title: nil)
    assert_not post.valid?
    assert_includes post.errors[:title], "can't be blank"
  end

  test "requires a script" do
    post = InstagramPost.new(title: "Orphan")
    assert_not post.valid?
    assert_includes post.errors[:script], "must exist"
  end

  test "enforces one instagram post per script" do
    @script.create_instagram_post!(title: "First")
    dup = InstagramPost.new(script: @script, title: "Second")
    assert_not dup.valid?
    assert_includes dup.errors[:script_id], "has already been taken"
  end

  test "reaches the owning user through its script" do
    post = @script.create_instagram_post!(title: "My caption")
    assert_equal @user, post.user
  end

  test "is destroyed with its script" do
    @script.create_instagram_post!(title: "Doomed")
    assert_difference("InstagramPost.count", -1) { @script.destroy }
  end

  test "owns chats via the polymorphic chattable association" do
    post = @script.create_instagram_post!(title: "My caption")
    chat = post.chats.create!

    assert_equal post, chat.chattable
    assert_equal "InstagramPost", chat.chattable_type
    assert_includes post.chats, chat
  end

  test "its chats are destroyed with it" do
    post = @script.create_instagram_post!(title: "Doomed")
    post.chats.create!

    assert_difference("Chat.count", -1) { post.destroy }
  end
end
