require "test_helper"

class SubstackSourceTest < ActiveSupport::TestCase
  def setup
    @user = create_user!(email: "source-test@cf.test")
  end

  # --- URL normalisation ---------------------------------------------------

  test "bare handle normalises to full feed url" do
    source = @user.substack_sources.build(feed_url: "lennysnewsletter")
    source.valid?
    assert_equal "https://lennysnewsletter.substack.com/feed", source.feed_url
    assert_equal "lennysnewsletter", source.handle
  end

  test "domain without scheme normalises to feed url" do
    source = @user.substack_sources.build(feed_url: "lennysnewsletter.substack.com")
    source.valid?
    assert_equal "https://lennysnewsletter.substack.com/feed", source.feed_url
  end

  test "full url without /feed appends /feed" do
    source = @user.substack_sources.build(feed_url: "https://lennysnewsletter.substack.com/")
    source.valid?
    assert_equal "https://lennysnewsletter.substack.com/feed", source.feed_url
  end

  test "full feed url stays unchanged" do
    source = @user.substack_sources.build(feed_url: "https://lennysnewsletter.substack.com/feed")
    source.valid?
    assert_equal "https://lennysnewsletter.substack.com/feed", source.feed_url
  end

  test "handle is extracted from substack subdomain" do
    source = @user.substack_sources.build(feed_url: "https://lennysnewsletter.substack.com/feed")
    source.valid?
    assert_equal "lennysnewsletter", source.handle
  end

  test "does not overwrite an explicitly set handle" do
    source = @user.substack_sources.build(feed_url: "lennysnewsletter", handle: "custom")
    source.valid?
    assert_equal "custom", source.handle
  end

  # --- Validations ---------------------------------------------------------

  test "requires feed_url" do
    source = @user.substack_sources.build(feed_url: "")
    refute source.valid?
    assert_includes source.errors[:feed_url], "can't be blank"
  end

  test "enforces uniqueness of feed_url per user" do
    @user.substack_sources.create!(feed_url: "lennysnewsletter.substack.com/feed")
    dup = @user.substack_sources.build(feed_url: "https://lennysnewsletter.substack.com/feed")
    refute dup.valid?
    assert_includes dup.errors[:feed_url], "has already been taken"
  end

  test "same feed_url is allowed for different users" do
    other = create_user!(email: "other-source@cf.test")
    @user.substack_sources.create!(feed_url: "lennysnewsletter.substack.com/feed")
    source = other.substack_sources.build(feed_url: "lennysnewsletter.substack.com/feed")
    assert source.valid?
  end

  # --- stale? --------------------------------------------------------------

  test "stale? is true when never fetched" do
    source = @user.substack_sources.build
    assert source.stale?
  end

  test "stale? is true when fetched more than an hour ago" do
    source = @user.substack_sources.build(fetched_at: 2.hours.ago)
    assert source.stale?
  end

  test "stale? is false when fetched within the last hour" do
    source = @user.substack_sources.build(fetched_at: 30.minutes.ago)
    refute source.stale?
  end

  # --- Associations --------------------------------------------------------

  test "belongs to user" do
    source = @user.substack_sources.create!(feed_url: "lennysnewsletter.substack.com/feed")
    assert_equal @user, source.user
  end

  test "destroying a source destroys its posts" do
    source = @user.substack_sources.create!(feed_url: "lennysnewsletter.substack.com/feed")
    source.substack_posts.create!(guid: "abc", title: "Post 1", published_at: Time.current)
    assert_difference "SubstackPost.count", -1 do
      source.destroy
    end
  end
end
