require "test_helper"

class InstagramPostsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = User.create!(email: "instagram-ctrl@cf.test", password: "password123")
    Creator.create!(user: @user, name: "Ada", topic: "AI",
                    goal: "grow audience", audience: "founders")
    @idea = @user.ideas.create!(title: "Ship faster", topic: "AI",
                                description: "tips on shipping")
    @script = @idea.scripts.create!(title: "s", style: "educational",
                                    length: "short", description: "d", custom_instructions: "p")
    sign_in @user
  end

  test "new redirects to a generate_instagram_post chat owned by the parent script" do
    get new_script_instagram_post_path(@script)

    assert_redirected_to new_chat_path(purpose: "generate_instagram_post",
                                       chattable_type: "Script", chattable_id: @script.id)
  end

  test "create saves the post and redirects to its show page" do
    assert_difference("InstagramPost.count", 1) do
      post script_instagram_post_path(@script),
           params: { instagram_post: { title: "My caption", hook: "h", body: "b" } }
    end
    assert_redirected_to script_instagram_post_path(@script)
  end

  test "create re-renders new with an invalid post" do
    assert_no_difference("InstagramPost.count") do
      post script_instagram_post_path(@script),
           params: { instagram_post: { title: "" } }
    end
    assert_response :unprocessable_entity
  end

  test "show renders the post" do
    @script.create_instagram_post!(title: "My caption", hook: "h", body: "b")
    get script_instagram_post_path(@script)
    assert_response :success
  end

  test "update changes the post and redirects" do
    @script.create_instagram_post!(title: "Old", hook: "h", body: "b")
    patch script_instagram_post_path(@script),
          params: { instagram_post: { title: "New" } }
    assert_redirected_to script_instagram_post_path(@script)
    assert_equal "New", @script.reload.instagram_post.title
  end

  test "destroy removes the post and redirects to the script" do
    @script.create_instagram_post!(title: "Doomed", hook: "h", body: "b")
    assert_difference("InstagramPost.count", -1) do
      delete script_instagram_post_path(@script)
    end
    assert_redirected_to script_path(@script)
  end

  test "cannot reach another user's script" do
    other = User.create!(email: "instagram-other@cf.test", password: "password123")
    other_idea = other.ideas.create!(title: "x", topic: "x", description: "x")
    other_script = other_idea.scripts.create!(title: "x", style: "x",
                                              length: "x", description: "x", custom_instructions: "x")

    get new_script_instagram_post_path(other_script)
    assert_response :not_found
  end

  test "redirects to sign-in when not authenticated" do
    sign_out @user
    get new_script_instagram_post_path(@script)
    assert_redirected_to new_user_session_path
  end
end
