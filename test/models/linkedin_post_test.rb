require "test_helper"

class LinkedinPostTest < ActiveSupport::TestCase
  def setup
    @user   = User.create!(email: "linkedin-model@cf.test", password: "password123")
    @idea   = @user.ideas.create!(title: "Ship faster", topic: "AI", description: "tips")
    @script = @idea.scripts.create!(title: "s", style: "educational",
                                    length: "short", description: "d", custom_instructions: "p")
  end

  test "reaches the owning user through its script" do
    post = @script.create_linkedin_post!(title: "My post")
    assert_equal @user, post.user
  end

  test "owns chats via the polymorphic chattable association" do
    post = @script.create_linkedin_post!(title: "My post")
    chat = post.chats.create!

    assert_equal post, chat.chattable
    assert_equal "LinkedinPost", chat.chattable_type
    assert_includes post.chats, chat
  end

  test "its chats are destroyed with it" do
    post = @script.create_linkedin_post!(title: "Doomed")
    post.chats.create!

    assert_difference("Chat.count", -1) { post.destroy }
  end
end
