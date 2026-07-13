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

  test "the previous default (gpt-4o-mini via GitHub Models) still resolves" do
    model = RubyLLM.models.find("gpt-4o-mini")

    assert_equal "gpt-4o-mini", model.id
    assert_equal "openai", model.provider
  end

  test "config.model_registry_file exists and is valid, non-empty JSON" do
    path = RubyLLM.config.model_registry_file

    assert File.exist?(path), "#{path} is missing — it's the fallback registry used whenever the `models` table is empty (e.g. every test run)"

    data = JSON.parse(File.read(path))
    assert data.is_a?(Array) && data.any?, "#{path} must contain at least one model"
  end
end
