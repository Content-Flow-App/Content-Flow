require "test_helper"

class ModelsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = create_user!(email: "models-index@cf.test")
    Creator.create!(user: @user, name: "Ada", topic: "AI",
                    goal: "grow audience", audience: "founders")
    sign_in @user
  end

  test "index renders successfully with only openai and anthropic models" do
    expected_count = RubyLLM.models.chat_models.all
      .count { |model| ApplicationController::CHAT_PROVIDERS.include?(model.provider.to_s) }

    get models_path

    assert_response :success
    assert_select "table tbody tr", count: expected_count
  end

  test "index lists no models from unconfigured providers" do
    get models_path

    assert_response :success
    assert_select "td", text: "gemini", count: 0
    assert_select "td", text: "openrouter", count: 0
  end

  test "show renders a real model" do
    model = Model.find_or_create_by!(provider: "anthropic", model_id: "claude-sonnet-5") do |m|
      m.name = "Claude Sonnet 5"
    end

    get model_path(model)

    assert_response :success
    assert_select "p", text: /claude-sonnet-5/
  end
end
