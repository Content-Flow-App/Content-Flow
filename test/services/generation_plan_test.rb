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
    assert_equal IdeaSchema,          plan_for("generate_idea").schema
    assert_equal ScriptSchema,        plan_for("generate_script").schema
    assert_equal LinkedinPostSchema,  plan_for("generate_linkedin_post").schema
    assert_equal TwitterPostSchema,   plan_for("generate_twitter_post").schema
    assert_equal InstagramPostSchema, plan_for("generate_instagram_post").schema
  end

  test "permitted_keys come from the schema's declared properties" do
    assert_equal IdeaSchema.properties.keys,          plan_for("generate_idea").permitted_keys
    assert_equal LinkedinPostSchema.properties.keys,  plan_for("generate_linkedin_post").permitted_keys
    assert_equal TwitterPostSchema.properties.keys,   plan_for("generate_twitter_post").permitted_keys
    assert_equal InstagramPostSchema.properties.keys, plan_for("generate_instagram_post").permitted_keys
  end

  test "raises UnknownPurpose for a chat with no generate purpose" do
    assert_raises(GenerationPlan::UnknownPurpose) do
      GenerationPlan.for(Chat.new(purpose: nil))
    end
  end

  # The assign_* helpers update an existing post or build a fresh one, so the
  # generation flow never creates a second post for the same script.
  class AssignPostTest < ActiveSupport::TestCase
    def setup
      @user   = User.create!(email: "assign@cf.test", password: "password123")
      @idea   = @user.ideas.create!(title: "i", topic: "t", description: "d")
      @script = @idea.scripts.create!(title: "s", style: "x", length: "x",
                                      description: "d", custom_instructions: "p")
    end

    test "assign_twitter_post builds a new post when none exists" do
      post = GenerationPlan.assign_twitter_post(@script, title: "Fresh")
      assert post.new_record?
      assert_equal "Fresh", post.title
    end

    test "assign_twitter_post updates the existing post in place" do
      existing = @script.create_twitter_post!(title: "Old")
      post = GenerationPlan.assign_twitter_post(@script, title: "New")
      assert_equal existing.id, post.id
      assert_equal "New", post.title
    end

    test "assign_instagram_post builds a new post when none exists" do
      post = GenerationPlan.assign_instagram_post(@script, title: "Fresh")
      assert post.new_record?
      assert_equal "Fresh", post.title
    end

    test "assign_instagram_post updates the existing post in place" do
      existing = @script.create_instagram_post!(title: "Old")
      post = GenerationPlan.assign_instagram_post(@script, title: "New")
      assert_equal existing.id, post.id
      assert_equal "New", post.title
    end
  end
end
