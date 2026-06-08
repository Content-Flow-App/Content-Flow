require "test_helper"

class SubstackFetchServiceTest < ActiveSupport::TestCase
  def setup
    @user   = User.create!(email: "fetch-svc@cf.test", password: "password123")
    @source = @user.substack_sources.create!(feed_url: "https://example.substack.com/feed")
  end

  # Minitest 6 has no Object#stub (see memory), so we swap the service's own
  # `read_body` seam for one that returns a canned body, then restore it in
  # `ensure`. Stubbing the service (which we own) instead of the global
  # URI.open keeps the swap leak-free and avoids any live HTTP.
  def with_body(body)
    klass = SubstackFetchService
    klass.send(:alias_method, :__orig_read_body, :read_body)
    klass.send(:define_method, :read_body) { body }
    yield
  ensure
    klass.send(:alias_method, :read_body, :__orig_read_body)
    klass.send(:remove_method, :__orig_read_body)
  end

  RSS_FIXTURE = <<~XML
    <?xml version="1.0" encoding="UTF-8"?>
    <rss version="2.0">
      <channel>
        <title>Example</title>
        <item>
          <title>First post</title>
          <link>https://example.com/p/1</link>
          <guid>https://example.com/p/1</guid>
          <pubDate>Tue, 03 Jun 2025 10:00:00 GMT</pubDate>
          <description>Hello &lt;b&gt;world&lt;/b&gt;.</description>
        </item>
        <item>
          <title>Second post</title>
          <link>https://example.com/p/2</link>
          <guid>https://example.com/p/2</guid>
          <pubDate>Wed, 04 Jun 2025 10:00:00 GMT</pubDate>
          <description>Another body.</description>
        </item>
      </channel>
    </rss>
  XML

  # --- happy path ----------------------------------------------------------

  test "imports posts from a valid RSS feed and clears any prior error" do
    @source.update_columns(fetch_error: "stale error from a previous run")

    result = with_body(RSS_FIXTURE) { SubstackFetchService.call(@source) }

    assert result, "expected the service to return true on success"
    assert_equal 2, @source.substack_posts.count
    post = @source.substack_posts.find_by(title: "First post")
    assert_not_nil post, "expected the first item imported"
    assert_equal "Hello world.", post.summary, "expected HTML tags stripped from the summary"
    assert_not_nil @source.reload.fetched_at
    assert_nil @source.fetch_error, "expected a successful fetch to clear the prior error"
  end

  # Note: re-fetch idempotency (no duplicate posts on refresh) is guaranteed by
  # the find_or_initialize_by(guid:) upsert and covered deterministically by the
  # guid-uniqueness test in substack_post_test.rb.

  # --- HTML response (publication moved to a custom domain) ----------------

  test "records a user-facing error when the feed URL returns HTML, not RSS" do
    html = "<!DOCTYPE html>\n<html><head><title>Lenny's Newsletter</title></head><body>…</body></html>"

    result = with_body(html) { SubstackFetchService.call(@source) }

    assert_not result, "expected the service to return false on an HTML response"
    assert_equal 0, @source.substack_posts.count
    assert_match(/web page, not an RSS feed/i, @source.fetch_error)
    # fetched_at stays nil so a Refresh will retry the source.
    assert_nil @source.reload.fetched_at
  end

  # --- well-formed XML that isn't a feed Feedjira recognises ---------------

  test "records an error when the body is XML but not a recognisable feed" do
    not_a_feed = %(<?xml version="1.0" encoding="UTF-8"?>\n<document><body>not a feed</body></document>)

    result = with_body(not_a_feed) { SubstackFetchService.call(@source) }

    assert_not result
    assert_match(/valid RSS feed/i, @source.fetch_error)
  end
end
