require "test_helper"

class UserTest < ActiveSupport::TestCase
  # ── Email format validation ───────────────────────────────────────────────

  test "accepts a standard email address" do
    user = User.new(email: "creator@example.com", password: TEST_PASSWORD, password_confirmation: TEST_PASSWORD)
    user.valid?
    assert_empty user.errors[:email]
  end

  test "accepts email with subdomain" do
    user = User.new(email: "creator@mail.example.co.uk", password: TEST_PASSWORD, password_confirmation: TEST_PASSWORD)
    user.valid?
    assert_empty user.errors[:email]
  end

  test "accepts email with plus tag" do
    user = User.new(email: "first+tag@example.com", password: TEST_PASSWORD, password_confirmation: TEST_PASSWORD)
    user.valid?
    assert_empty user.errors[:email]
  end

  test "rejects email without a TLD" do
    user = User.new(email: "creator@localhost", password: TEST_PASSWORD, password_confirmation: TEST_PASSWORD)
    user.valid?
    assert_includes user.errors[:email], "is invalid"
  end

  test "rejects email without an @ sign" do
    user = User.new(email: "not-an-email", password: TEST_PASSWORD, password_confirmation: TEST_PASSWORD)
    user.valid?
    assert_includes user.errors[:email], "is invalid"
  end

  test "rejects email with spaces" do
    user = User.new(email: "bad email@example.com", password: TEST_PASSWORD, password_confirmation: TEST_PASSWORD)
    user.valid?
    assert_includes user.errors[:email], "is invalid"
  end

  # ── Password length ──────────────────────────────────────────────────────

  test "rejects password shorter than 15 characters" do
    user = User.new(email: "len@example.com", password: "Short1!", password_confirmation: "Short1!")
    user.valid?
    assert user.errors[:password].any? { |e| e.include?("minimum") },
           "expected a minimum-length error, got: #{user.errors[:password]}"
  end

  test "accepts password of exactly 15 characters" do
    pwd = "Exactly15Char!1"
    assert_equal 15, pwd.length
    user = User.new(email: "len15@example.com", password: pwd, password_confirmation: pwd)
    user.valid?
    assert_empty user.errors[:password]
  end

  # ── Password complexity ───────────────────────────────────────────────────

  test "rejects password without a number" do
    pwd = "NoNumbersHere!!!"
    user = User.new(email: "num@example.com", password: pwd, password_confirmation: pwd)
    user.valid?
    assert_includes user.errors[:password], "must include at least one number"
  end

  test "rejects password without a symbol" do
    pwd = "NoSymbolsHere123"
    user = User.new(email: "sym@example.com", password: pwd, password_confirmation: pwd)
    user.valid?
    assert_includes user.errors[:password], "must include at least one symbol"
  end

  test "accepts password with both number and symbol" do
    user = User.new(email: "ok@example.com", password: TEST_PASSWORD, password_confirmation: TEST_PASSWORD)
    user.valid?
    assert_empty user.errors[:password]
  end

  test "reports all complexity violations at once" do
    pwd = "abcdefghijklmno"
    user = User.new(email: "all@example.com", password: pwd, password_confirmation: pwd)
    user.valid?
    assert_includes user.errors[:password], "must include at least one number"
    assert_includes user.errors[:password], "must include at least one symbol"
  end

  # ── Confirmable ───────────────────────────────────────────────────────────

  test "new user is unconfirmed by default" do
    user = create_user!(email: "unconf@example.com", confirmed: false)
    assert_nil user.confirmed_at
    refute user.confirmed?
  end

  test "confirmed user has confirmed_at set" do
    user = create_user!(email: "conf@example.com")
    assert_not_nil user.confirmed_at
    assert user.confirmed?
  end

  test "confirmation token is generated for unconfirmed user" do
    user = create_user!(email: "token@example.com", confirmed: false)
    assert_not_nil user.confirmation_token
  end
end
