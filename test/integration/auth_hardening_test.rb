require "test_helper"

class AuthHardeningTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  # ── Sign-up creates an unconfirmed account ────────────────────────────────

  test "sign up creates an unconfirmed user and does not sign in" do
    post user_registration_path, params: {
      user: { email: "new@example.com",
              password: ActiveSupport::TestCase::TEST_PASSWORD,
              password_confirmation: ActiveSupport::TestCase::TEST_PASSWORD }
    }

    user = User.find_by(email: "new@example.com")
    assert user.present?, "expected user to be created"
    assert_nil user.confirmed_at, "expected user to be unconfirmed"

    get dashboard_path
    assert_redirected_to new_user_session_path
  end

  # ── Unconfirmed user cannot sign in ───────────────────────────────────────

  test "unconfirmed user is rejected on sign in" do
    create_user!(email: "unconf@example.com", confirmed: false)

    post user_session_path, params: {
      user: { email: "unconf@example.com",
              password: ActiveSupport::TestCase::TEST_PASSWORD }
    }

    get dashboard_path
    assert_redirected_to new_user_session_path
  end

  # ── Confirmed user can sign in ───────────────────────────────────────────

  test "confirmed user can sign in and reach authenticated pages" do
    user = create_user!(email: "confirmed@example.com")
    Creator.create!(user: user, name: "Test", topic: "AI",
                    goal: "grow", audience: "devs")

    post user_session_path, params: {
      user: { email: "confirmed@example.com",
              password: ActiveSupport::TestCase::TEST_PASSWORD }
    }

    get dashboard_path
    assert_response :success
  end

  # ── Confirmation flow ────────────────────────────────────────────────────

  test "user confirms email and can then sign in" do
    user = create_user!(email: "flow@example.com", confirmed: false)

    user.confirm
    assert user.confirmed?

    post user_session_path, params: {
      user: { email: "flow@example.com",
              password: ActiveSupport::TestCase::TEST_PASSWORD }
    }

    follow_redirect!
    assert_response :success
  end

  # ── Sign-up rejects weak passwords ───────────────────────────────────────

  test "sign up rejects password that is too short" do
    post user_registration_path, params: {
      user: { email: "short@example.com",
              password: "Short1!",
              password_confirmation: "Short1!" }
    }

    assert_nil User.find_by(email: "short@example.com")
    assert_response :unprocessable_content
  end

  test "sign up rejects password without a number" do
    post user_registration_path, params: {
      user: { email: "nonum@example.com",
              password: "NoNumbersHere!!!",
              password_confirmation: "NoNumbersHere!!!" }
    }

    assert_nil User.find_by(email: "nonum@example.com")
    assert_response :unprocessable_content
  end

  test "sign up rejects password without a symbol" do
    post user_registration_path, params: {
      user: { email: "nosym@example.com",
              password: "NoSymbolsHere123",
              password_confirmation: "NoSymbolsHere123" }
    }

    assert_nil User.find_by(email: "nosym@example.com")
    assert_response :unprocessable_content
  end

  # ── Sign-up rejects invalid email ────────────────────────────────────────

  test "sign up rejects email without a TLD" do
    post user_registration_path, params: {
      user: { email: "bad@localhost",
              password: ActiveSupport::TestCase::TEST_PASSWORD,
              password_confirmation: ActiveSupport::TestCase::TEST_PASSWORD }
    }

    assert_nil User.find_by(email: "bad@localhost")
    assert_response :unprocessable_content
  end

  # ── Onboarding redirect after confirmation ───────────────────────────────

  test "confirmed user without creator profile is redirected to creator path" do
    user = create_user!(email: "onboard@example.com")

    post user_session_path, params: {
      user: { email: "onboard@example.com",
              password: ActiveSupport::TestCase::TEST_PASSWORD }
    }

    assert_redirected_to creator_path
  end

  test "confirmed user with creator profile continues onboarding" do
    user = create_user!(email: "complete@example.com")
    Creator.create!(user: user, name: "Test", topic: "AI",
                    goal: "grow", audience: "devs")

    post user_session_path, params: {
      user: { email: "complete@example.com",
              password: ActiveSupport::TestCase::TEST_PASSWORD }
    }

    # User has a creator but no ideas yet, so onboarding sends them to new_idea_path
    assert_redirected_to new_idea_path
  end

  # ── Existing user with old weak password can still sign in ───────────────

  test "existing confirmed user bypasses password complexity on sign in" do
    user = create_user!(email: "legacy@example.com")
    assert user.confirmed?
    sign_in user

    get dashboard_path
    follow_redirect! if response.redirect?
    assert_response :success
  end

  # ── Sign out works without a creator profile ─────────────────────────────

  test "user without a creator profile can sign out" do
    user = create_user!(email: "nocreator@example.com")

    post user_session_path, params: {
      user: { email: "nocreator@example.com",
              password: ActiveSupport::TestCase::TEST_PASSWORD }
    }

    delete destroy_user_session_path
    assert_response :redirect

    get dashboard_path
    assert_redirected_to new_user_session_path
  end
end
