require "test_helper"

# Unit tests for the declarative bits of GenerationPlan. The behavioural slots
# (owner_resolver / persist / redirect_target) run in the controller's context
# via instance_exec, so they're covered by GenerationsControllerTest; here we
# pin the purpose -> schema mapping and the allow-list derivation.
class GenerationPlanTest < ActiveSupport::TestCase
  def plan_for(purpose)
    GenerationPlan.for(Chat.new(purpose: purpose))
  end

  test "maps each purpose to its schema" do
    assert_equal IdeaSchema,         plan_for("generate_idea").schema
    assert_equal ScriptSchema,       plan_for("generate_script").schema
    assert_equal LinkedinPostSchema, plan_for("generate_linkedin_post").schema
  end

  test "permitted_keys come from the schema's declared properties" do
    assert_equal IdeaSchema.properties.keys,        plan_for("generate_idea").permitted_keys
    assert_equal LinkedinPostSchema.properties.keys, plan_for("generate_linkedin_post").permitted_keys
  end

  test "raises UnknownPurpose for a chat with no generate purpose" do
    assert_raises(GenerationPlan::UnknownPurpose) do
      GenerationPlan.for(Chat.new(purpose: nil))
    end
  end
end
