require "test_helper"

class ScriptsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = User.create!(email: "scripts@cf.test", password: "password123")
    Creator.create!(user: @user, name: "Ada", topic: "AI",
                    goal: "grow audience", audience: "founders")
    @idea = @user.ideas.create!(title: "Ship faster", topic: "AI",
                                description: "tips on shipping")
    sign_in @user
  end

  test "new redirects to a generate_script chat owned by the parent idea" do
    get new_idea_script_path(@idea)

    assert_redirected_to new_chat_path(purpose: "generate_script",
                                       chattable_type: "Idea", chattable_id: @idea.id)
  end
end
