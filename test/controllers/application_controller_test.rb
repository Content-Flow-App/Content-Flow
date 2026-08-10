require "test_helper"

# Unit-level coverage for the chat_model_provider_label/chat_model_label
# helpers, exercised directly against duck-typed model doubles rather than
# through the full request/registry stack — these are pure label-formatting
# rules and shouldn't need a live RubyLLM registry (real or fallback JSON) to
# verify. See test/controllers/models_controller_test.rb for the integration
# path (real registry rows, rendered through the /models page).
class ApplicationControllerLabelHelpersTest < ActiveSupport::TestCase
  FakeProviderClass = Struct.new(:name)
  FakeModel = Struct.new(:metadata, :provider_class, :provider, :name)

  setup { @controller = ApplicationController.new }

  test "returns the real publisher's display name for a known OpenRouter slug" do
    kimi = FakeModel.new({ "real_publisher" => "moonshotai" },
                         FakeProviderClass.new("Openrouter"), "openrouter", "Kimi K3")

    assert_equal "Moonshot AI", @controller.chat_model_provider_label(kimi)
  end

  test "reads a symbol-keyed real_publisher the same as a string-keyed one" do
    glm = FakeModel.new({ real_publisher: "zhipu" }, FakeProviderClass.new("Openrouter"), "openrouter", "GLM-5.2")

    assert_equal "Zhipu", @controller.chat_model_provider_label(glm)
  end

  test "falls back to the raw slug when real_publisher isn't in the display-name map" do
    unmapped = FakeModel.new({ "real_publisher" => "some-new-publisher" },
                             FakeProviderClass.new("Openrouter"), "openrouter", "Some Model")

    assert_equal "some-new-publisher", @controller.chat_model_provider_label(unmapped)
  end

  test "falls back to provider_class name when no real_publisher is present" do
    deepseek = FakeModel.new({}, FakeProviderClass.new("Deepseek"), "deepseek", "DeepSeek V4 Flash")

    assert_equal "Deepseek", @controller.chat_model_provider_label(deepseek)
  end

  test "falls back to the bare provider string when provider_class is nil" do
    unknown = FakeModel.new({}, nil, "mystery", "Mystery Model")

    assert_equal "mystery", @controller.chat_model_provider_label(unknown)
  end

  test "chat_model_label combines the provider label and the model name" do
    kimi = FakeModel.new({ "real_publisher" => "moonshotai" },
                         FakeProviderClass.new("Openrouter"), "openrouter", "Kimi K3")

    assert_equal "Moonshot AI - Kimi K3", @controller.chat_model_label(kimi)
  end
end
