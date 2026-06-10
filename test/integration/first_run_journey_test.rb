require "test_helper"

# First-run journey: a brand-new user walks the full onboarding path from sign-up
# to a saved LinkedIn post without ever touching the real LLM API.
#
# What this test covers that the unit/controller tests don't:
#   - The Devise registration flow sets the session so subsequent requests are
#     authenticated.
#   - The check_creator_exist before_action gates every page until a creator
#     profile is saved.
#   - The onboarding_path_for helper steers each redirect toward the next missing
#     step (creator → idea → script → post).
#   - The full chat → generate cycle runs once per content type: idea, script,
#     post. StructuredExtraction is stubbed so no network call is made.
#
# "E2E" here means full HTTP-layer integration (ActionDispatch), not a browser
# test. Capybara/Selenium is not installed.
class FirstRunJourneyTest < ActionDispatch::IntegrationTest
  # perform_enqueued_jobs: the save action only *enqueues* GenerationJob; the
  # test adapter records jobs instead of running them, so we wrap each save in
  # perform_enqueued_jobs to run the job inline, as Solid Queue would async.
  include ActiveJob::TestHelper

  # Swaps StructuredExtraction.extract for the duration of the block, returning
  # `result` as the payload each time it is called. Identical to the helper in
  # GenerationJobTest — kept local so the journey test is self-contained.
  def with_extraction(result)
    original = StructuredExtraction.method(:extract)
    StructuredExtraction.define_singleton_method(:extract) { |**| result }
    yield
  ensure
    StructuredExtraction.define_singleton_method(:extract, original)
  end

  # Creates a chat via HTTP (as the journey user would), adds an assistant
  # reply in-process (bypassing the enqueued ChatResponseJob so no LLM call
  # fires), and returns the Chat record.
  def create_chat_with_reply(chattable_type:, chattable_id:, purpose:)
    post chats_path, params: {
      chat: {
        prompt: "Help me build this.",
        chattable_type: chattable_type,
        chattable_id: chattable_id,
        purpose: purpose
      }
    }
    assert_response :redirect

    chat = Chat.last
    chat.messages.create!(role: "assistant", content: "Here's a solid draft.")
    chat
  end

  test "sign up → creator → generate idea → generate script → generate linkedin post" do
    # ── 1. Sign up ──────────────────────────────────────────────────────────
    post user_registration_path, params: {
      user: { email: "journey@cf.test", password: "password123",
              password_confirmation: "password123" }
    }
    # after_sign_up_path_for routes a new user to creator_path (no creator yet)
    assert_redirected_to creator_path

    # ── 2. Create creator profile ───────────────────────────────────────────
    post creator_path, params: {
      creator: { name: "Journey User", topic: "AI tooling",
                 goal: "grow audience", audience: "indie founders" }
    }
    # onboarding_path_for: creator present, no ideas yet → new_idea_path
    assert_redirected_to new_idea_path

    # ── 3. ideas#new → redirects to generate_idea chat ─────────────────────
    user = User.find_by!(email: "journey@cf.test")
    get new_idea_path
    assert_redirected_to new_chat_path(purpose: "generate_idea",
                                       chattable_type: "User",
                                       chattable_id: user.id)

    # ── 4. Generate an idea ─────────────────────────────────────────────────
    idea_chat = create_chat_with_reply(chattable_type: "User", chattable_id: user.id,
                                       purpose: "generate_idea")

    idea_payload = { "title" => "AI Workflow Guide", "description" => "A punchy angle.", "topic" => "AI tooling" }
    assert_difference -> { user.ideas.count }, 1 do
      with_extraction(idea_payload) do
        perform_enqueued_jobs(only: GenerationJob) { post chat_generation_path(idea_chat) }
      end
    end

    idea = user.ideas.order(:created_at).last
    assert_equal "AI Workflow Guide", idea.title
    # The HTTP response is the html fallback back to the chat; the navigation
    # to the new record arrives over the chat's Turbo Stream (GenerationJobTest).
    assert_redirected_to chat_path(idea_chat)

    # ── 5. scripts#new → redirects to generate_script chat ─────────────────
    get new_idea_script_path(idea)
    assert_redirected_to new_chat_path(purpose: "generate_script",
                                       chattable_type: "Idea",
                                       chattable_id: idea.id)

    # ── 6. Generate a script ────────────────────────────────────────────────
    script_chat = create_chat_with_reply(chattable_type: "Idea", chattable_id: idea.id,
                                         purpose: "generate_script")

    script_payload = { "title" => "Three Tools You Need", "description" => "Step-by-step.",
                       "style" => "educational", "length" => "short" }
    assert_difference -> { idea.scripts.count }, 1 do
      with_extraction(script_payload) do
        perform_enqueued_jobs(only: GenerationJob) { post chat_generation_path(script_chat) }
      end
    end

    script = idea.scripts.order(:created_at).last
    assert_equal "Three Tools You Need", script.title
    assert_redirected_to chat_path(script_chat)

    # ── 7. linkedin_posts#new → redirects to generate_linkedin_post chat ────
    get new_script_linkedin_post_path(script)
    assert_redirected_to new_chat_path(purpose: "generate_linkedin_post",
                                       chattable_type: "Script",
                                       chattable_id: script.id)

    # ── 8. Generate a LinkedIn post ─────────────────────────────────────────
    post_chat = create_chat_with_reply(chattable_type: "Script", chattable_id: script.id,
                                       purpose: "generate_linkedin_post")

    post_payload = { "title" => "Launch Post", "hook" => "Stop scrolling.", "body" => "Here's the guide." }
    assert_difference -> { LinkedinPost.count }, 1 do
      with_extraction(post_payload) do
        perform_enqueued_jobs(only: GenerationJob) { post chat_generation_path(post_chat) }
      end
    end

    linkedin_post = script.reload.linkedin_post
    assert linkedin_post.present?, "expected a LinkedIn post to be created"
    assert_equal "Launch Post", linkedin_post.title
    assert_redirected_to chat_path(post_chat)

    # ── 9. Onboarding complete ──────────────────────────────────────────────
    assert user.reload.onboarding_complete?,
           "expected onboarding to be complete after generating idea, script, and post"
  end
end
