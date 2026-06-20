require "test_helper"

class SubstackPostTest < ActiveSupport::TestCase
  def setup
    @user   = create_user!(email: "post-test@cf.test")
    @source = @user.substack_sources.create!(feed_url: "lennysnewsletter.substack.com/feed")
  end

  test "guid must be unique within a source" do
    @source.substack_posts.create!(guid: "abc-123", published_at: Time.current)
    dup = @source.substack_posts.build(guid: "abc-123", published_at: Time.current)
    refute dup.valid?
    assert_includes dup.errors[:guid], "has already been taken"
  end

  test "same guid is allowed across different sources" do
    other_source = @user.substack_sources.create!(feed_url: "another.substack.com/feed")
    @source.substack_posts.create!(guid: "shared-guid", published_at: Time.current)
    post = other_source.substack_posts.build(guid: "shared-guid", published_at: Time.current)
    assert post.valid?
  end

  test "user is reachable through source" do
    post = @source.substack_posts.create!(guid: "xyz", published_at: Time.current)
    assert_equal @user, post.user
  end

  test "default scope orders by published_at descending" do
    @source.substack_posts.create!(guid: "old", published_at: 2.days.ago)
    @source.substack_posts.create!(guid: "new", published_at: 1.day.ago)
    first_guid = @source.substack_posts.first.guid
    assert_equal "new", first_guid
  end
end
