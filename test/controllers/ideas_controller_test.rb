require "test_helper"

class IdeasControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = create_user!(email: "ideas@cf.test")
    Creator.create!(user: @user, name: "Ada", topic: "AI",
                    goal: "grow audience", audience: "founders")
    @idea = @user.ideas.create!(title: "Ship faster", topic: "AI",
                                description: "tips on shipping")
    sign_in @user
  end

  test "new redirects to a generate_idea chat owned by the current user" do
    get new_idea_path

    assert_redirected_to new_chat_path(purpose: "generate_idea",
                                       chattable_type: "User", chattable_id: @user.id)
  end

  test "editing an existing idea still works (update persists changes)" do
    patch idea_path(@idea), params: { idea: { title: "Ship even faster" } }

    assert_redirected_to idea_path(@idea)
    assert_equal "Ship even faster", @idea.reload.title
  end
end
