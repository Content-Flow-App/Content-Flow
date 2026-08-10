require "test_helper"

# Guards config/initializers/ruby_llm.rb and config/ruby_llm_models.json.
#
# Every Chat.create! (in *any* test — see e.g. test/models/twitter_post_test.rb,
# which has nothing to do with LLMs) triggers acts_as_chat's before_save
# callback, which resolves `RubyLLM.config.default_model` against the
# registry. If that model isn't resolvable, dozens of unrelated tests fail
# with a cryptic RubyLLM::ModelNotFoundError instead of one clear failure
# here. This happened once already: default_model was changed to
# claude-sonnet-5 before the test DB's fallback registry knew about it (the
# test `models` table is always empty — this app seeds no fixtures — so
# resolution falls back to config/ruby_llm_models.json instead of the DB).
class RubyLlmRegistryTest < ActiveSupport::TestCase
  test "the default model resolves to a real registry entry" do
    model = RubyLLM.models.find(RubyLLM.config.default_model)

    assert_equal "claude-sonnet-5", model.id
    assert_equal "anthropic", model.provider
  end

  test "claude-opus-5 resolves (added to the fallback registry ahead of the gem, like claude-sonnet-5)" do
    model = RubyLLM.models.find("claude-opus-5")

    assert_equal "claude-opus-5", model.id
    assert_equal "anthropic", model.provider
  end

  test "claude-haiku-4-5-20251001 resolves" do
    model = RubyLLM.models.find("claude-haiku-4-5-20251001")

    assert_equal "claude-haiku-4-5-20251001", model.id
    assert_equal "anthropic", model.provider
  end

  test "deepseek-v4-flash resolves" do
    model = RubyLLM.models.find("deepseek-v4-flash")

    assert_equal "deepseek-v4-flash", model.id
    assert_equal "deepseek", model.provider
  end

  test "deepseek-v4-pro resolves" do
    model = RubyLLM.models.find("deepseek-v4-pro")

    assert_equal "deepseek-v4-pro", model.id
    assert_equal "deepseek", model.provider
  end

  test "moonshotai/kimi-k3 resolves under the openrouter provider, tagged with its real publisher" do
    model = RubyLLM.models.find("moonshotai/kimi-k3")

    assert_equal "moonshotai/kimi-k3", model.id
    assert_equal "openrouter", model.provider
    assert_equal "moonshotai", model.metadata[:real_publisher]
  end

  test "z-ai/glm-5.2 resolves under the openrouter provider, tagged with its real publisher" do
    model = RubyLLM.models.find("z-ai/glm-5.2")

    assert_equal "z-ai/glm-5.2", model.id
    assert_equal "openrouter", model.provider
    assert_equal "zhipu", model.metadata[:real_publisher]
  end

  # GitHub Models was dropped entirely — see config/initializers/ruby_llm.rb.
  # Guards against it quietly coming back (e.g. a merge conflict resurrecting
  # the old openai_api_key/openai_api_base lines), which would put chats at
  # risk of the exact failure in issue #45 again.
  test "no OpenAI-compatible provider (GitHub Models) is configured" do
    assert_nil RubyLLM.config.openai_api_key
    assert_nil RubyLLM.config.openai_api_base
  end

  test "config.model_registry_file exists and is valid, non-empty JSON" do
    path = RubyLLM.config.model_registry_file

    assert File.exist?(path),
           "#{path} is missing — the fallback registry used whenever `models` is empty (e.g. every test run)"

    data = JSON.parse(File.read(path))
    assert data.is_a?(Array) && data.any?, "#{path} must contain at least one model"
  end
end
