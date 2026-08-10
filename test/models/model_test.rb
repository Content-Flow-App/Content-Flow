require "test_helper"

class ModelTest < ActiveSupport::TestCase
  # OpenRouter's own API has no publisher field, and RubyLLM's
  # save_to_database (called by Model.refresh!) overwrites the `metadata`
  # column wholesale from the live catalog on every refresh — so
  # tag_real_publishers! has to be able to (re)apply the tag after the fact,
  # not just at row-creation time. Exercised directly (not via Model.refresh!,
  # which hits OpenRouter's live API) since this is the part of the mechanism
  # that doesn't require a real network call.
  test "tag_real_publishers! sets real_publisher for known OpenRouter rows" do
    kimi = Model.create!(provider: "openrouter", model_id: "moonshotai/kimi-k3", name: "Kimi K3")
    glm = Model.create!(provider: "openrouter", model_id: "z-ai/glm-5.2", name: "GLM-5.2")

    Model.tag_real_publishers!

    assert_equal "moonshotai", kimi.reload.metadata["real_publisher"]
    assert_equal "zhipu", glm.reload.metadata["real_publisher"]
  end

  test "tag_real_publishers! is safe to call again after a refresh wipes metadata" do
    kimi = Model.create!(provider: "openrouter", model_id: "moonshotai/kimi-k3", name: "Kimi K3",
                         metadata: { "real_publisher" => "moonshotai" })

    # Simulates what RubyLLM::ActiveRecord::ModelMethods#save_to_database does
    # on every Model.refresh! — overwrite metadata from the live registry,
    # which carries no real_publisher key of its own.
    kimi.update!(metadata: {})

    Model.tag_real_publishers!

    assert_equal "moonshotai", kimi.reload.metadata["real_publisher"]
  end

  test "tag_real_publishers! preserves other metadata keys already on the row" do
    kimi = Model.create!(provider: "openrouter", model_id: "moonshotai/kimi-k3", name: "Kimi K3",
                         metadata: { "some_registry_key" => "value" })

    Model.tag_real_publishers!

    metadata = kimi.reload.metadata
    assert_equal "moonshotai", metadata["real_publisher"]
    assert_equal "value", metadata["some_registry_key"]
  end

  test "tag_real_publishers! does nothing for rows outside the map" do
    anthropic = Model.create!(provider: "anthropic", model_id: "claude-sonnet-5", name: "Claude Sonnet 5")
    deepseek = Model.create!(provider: "deepseek", model_id: "deepseek-v4-flash", name: "DeepSeek V4 Flash")

    Model.tag_real_publishers!

    assert_equal({}, anthropic.reload.metadata)
    assert_equal({}, deepseek.reload.metadata)
  end

  test "tag_real_publishers! does not raise when a mapped OpenRouter row hasn't been created yet" do
    assert_nothing_raised { Model.tag_real_publishers! }
  end
end
