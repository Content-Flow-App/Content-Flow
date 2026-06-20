require "test_helper"

class LinkedinPostsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = create_user!(email: "posts@cf.test")
    Creator.create!(user: @user, name: "Ada", topic: "AI",
                    goal: "grow audience", audience: "founders")
    @idea = @user.ideas.create!(title: "Ship faster", topic: "AI",
                                description: "tips on shipping")
    @script = @idea.scripts.create!(title: "s", style: "educational",
                                    length: "short", description: "d", custom_instructions: "p")
    sign_in @user
  end

  test "new redirects to a generate_linkedin_post chat owned by the parent script" do
    get new_script_linkedin_post_path(@script)

    assert_redirected_to new_chat_path(purpose: "generate_linkedin_post",
                                       chattable_type: "Script", chattable_id: @script.id)
  end
end
