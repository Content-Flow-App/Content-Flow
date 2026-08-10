require "test_helper"

class ModelsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = create_user!(email: "models-index@cf.test")
    Creator.create!(user: @user, name: "Ada", topic: "AI",
                    goal: "grow audience", audience: "founders")
    sign_in @user
  end

  test "index renders successfully with exactly the allowlisted models" do
    get models_path

    assert_response :success
    assert_select "table tbody tr", count: ApplicationController::CHAT_MODELS.size
  end

  test "index lists no models outside the allowlist" do
    get models_path

    assert_response :success
    assert_select "td", text: "gemini", count: 0
    assert_select "td", text: "openrouter", count: 0
    # Same provider (openai) as an allowlisted model, but not a chat model —
    # this is exactly what the exact [provider, id] allowlist excludes.
    assert_select "td", text: "dall-e-3", count: 0
    assert_select "td", text: "whisper-1", count: 0
    # Same bare id as an allowlisted model, but under an unconfigured
    # provider (azure) — the other false positive the allowlist excludes.
    assert_select "td", text: "azure", count: 0
  end

  # OpenRouter fronts multiple publishers under RubyLLM's single `openrouter`
  # provider tag — the provider column must show the real publisher, not
  # "Openrouter", or the switcher/registry page lies about what actually
  # generated the reply. Mirrors the equivalent test for the GitHub
  # Models-routed Mistral/DeepSeek rows, removed in issue #45.
  test "index shows the real publisher for OpenRouter-routed models, not OpenRouter" do
    get models_path

    assert_response :success
    assert_select "#model_openrouter_moonshotai_kimi-k3 td:first-child", text: "Moonshot AI"
    assert_select "#model_openrouter_z-ai_glm-5_2 td:first-child", text: "Zhipu"
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
