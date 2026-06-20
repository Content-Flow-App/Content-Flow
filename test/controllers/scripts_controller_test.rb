require "test_helper"

class ScriptsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = create_user!(email: "scripts@cf.test")
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

  test "update persists custom_instructions (the renamed system-prompt field)" do
    script = @idea.scripts.create!(title: "Hook them", style: "educational",
                                   length: "short", description: "a punchy script")

    patch script_path(script), params: { script: { custom_instructions: "Be concise and witty." } }

    assert_redirected_to script_path(script)
    assert_equal "Be concise and witty.", script.reload.custom_instructions
  end
end
