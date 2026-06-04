require "test_helper"

class LlmContextTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(email: "ctx-owner@cf.test", password: "password123")
    @creator = Creator.create!(user: @user, name: "Ada", topic: "AI",
                               goal: "grow audience", audience: "founders")
    @idea = @user.ideas.create!(title: "Ship faster", topic: "AI",
                                description: "tips on shipping")
    @script = Script.create!(idea: @idea, title: "Hook them", style: "educational",
                             length: "short", description: "a punchy script",
                             system_prompt: "Be concise and witty.")
    @post = LinkedinPost.create!(script: @script, title: "Post one",
                                 hook: "Stop doing X", body: "Here is why...")
  end

  test "nil chattable yields no instructions" do
    assert_nil LlmContext.for(nil)
  end

  test "an owner with no creator profile yields no instructions" do
    orphan = User.create!(email: "no-creator@cf.test", password: "password123")
    assert_nil LlmContext.for(orphan)
  end

  test "user-level context includes only the creator profile" do
    text = LlmContext.for(@user)

    assert_includes text, "CREATOR PROFILE"
    assert_includes text, "Ada"
    assert_includes text, "founders"
    refute_includes text, "PARENT IDEA"
  end

  test "idea context layers creator profile then the idea" do
    text = LlmContext.for(@idea)

    assert_includes text, "CREATOR PROFILE"
    assert_includes text, "PARENT IDEA"
    assert_includes text, "Ship faster"
    refute_includes text, "PARENT SCRIPT"
    # Creator layer precedes the idea layer.
    assert_operator text.index("CREATOR PROFILE"), :<, text.index("PARENT IDEA")
  end

  test "script context adds the parent idea and the script system_prompt" do
    text = LlmContext.for(@script)

    assert_includes text, "CREATOR PROFILE"
    assert_includes text, "PARENT IDEA"
    assert_includes text, "PARENT SCRIPT"
    assert_includes text, "SCRIPT INSTRUCTIONS"
    assert_includes text, "Be concise and witty."
    refute_includes text, "THIS LINKEDIN POST"
  end

  test "linkedin post context layers the whole ancestry chain in order" do
    text = LlmContext.for(@post)

    assert_includes text, "CREATOR PROFILE"
    assert_includes text, "PARENT IDEA"
    assert_includes text, "PARENT SCRIPT"
    assert_includes text, "THIS LINKEDIN POST"
    assert_includes text, "Stop doing X"

    creator_at = text.index("CREATOR PROFILE")
    idea_at    = text.index("PARENT IDEA")
    script_at  = text.index("PARENT SCRIPT")
    post_at    = text.index("THIS LINKEDIN POST")
    assert creator_at < idea_at, "creator before idea"
    assert idea_at < script_at,  "idea before script"
    assert script_at < post_at,  "script before post"
  end

  test "a script with no system_prompt omits the instructions block" do
    @script.update!(system_prompt: nil)
    text = LlmContext.for(@script)

    assert_includes text, "PARENT SCRIPT"
    refute_includes text, "SCRIPT INSTRUCTIONS"
  end
end
