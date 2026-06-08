require "open-uri"

# Fetches and caches posts from a single SubstackSource's RSS feed.
#
# Uses feedjira instead of stdlib rss: Substack feeds embed raw HTML in
# description elements which breaks REXML (the strict XML parser behind the
# stdlib gem). Feedjira uses Nokogiri and handles real-world malformed feeds.
#
# Usage:
#   SubstackFetchService.call(source) # => true on success, false on network error
#
# Caps at MAX_ENTRIES so a large feed doesn't hammer the DB on first import.
class SubstackFetchService
  TIMEOUT     = 10
  MAX_ENTRIES = 20

  # Raised when we couldn't import a feed, carrying a user-facing message that
  # gets recorded on the source so the UI can explain what went wrong instead
  # of leaving the feed silently empty.
  class FetchError < StandardError; end

  def self.call(source)
    new(source).call
  end

  def initialize(source)
    @source = source
  end

  # Returns true on success, false on failure. On success it stamps fetched_at
  # and clears any prior error. On a known failure it records a user-facing
  # reason in `fetch_error` (and leaves fetched_at untouched, so a Refresh will
  # retry). Unexpected errors are logged and recorded generically.
  def call
    feed = fetch_feed
    upsert_posts(feed.entries)
    @source.update_columns(fetched_at: Time.current, fetch_error: nil)
    true
  rescue FetchError => e
    Rails.logger.warn("SubstackFetchService (source #{@source.id}): #{e.message}")
    @source.update_columns(fetch_error: e.message)
    false
  rescue => e
    Rails.logger.error("SubstackFetchService error (source #{@source.id}): #{e.message}")
    @source.update_columns(fetch_error: "Something went wrong fetching this feed. Please try again.")
    false
  end

  private

  def fetch_feed
    body = read_body

    # A publication that has moved to a custom domain serves an HTML page (not
    # RSS) at its *.substack.com/feed URL. Detect that up front so we can tell
    # the user precisely what's wrong rather than emit a vague parser error.
    if looks_like_html?(body)
      raise FetchError, "This URL returned a web page, not an RSS feed — if the publication moved to a custom domain, add that domain's /feed URL instead."
    end

    Feedjira.parse(body)
  rescue Feedjira::NoParserAvailable
    raise FetchError, "This doesn't look like a valid RSS feed. Double-check the feed URL."
  rescue OpenURI::HTTPError => e
    raise FetchError, "The feed responded with an error (#{e.message}). Check that the URL is correct."
  rescue SocketError, Timeout::Error, RuntimeError => e
    raise FetchError, "Couldn't reach this feed. Check the URL and your connection, then try again."
  end

  def looks_like_html?(body)
    head = body.to_s.lstrip[0, 200].downcase
    head.start_with?("<!doctype html", "<html") || head.include?("<head")
  end

  # The single network read, isolated so it's the one seam tests stub (no live
  # HTTP). open-uri follows redirects automatically, which handles Substack
  # publications that have moved to a custom domain (they 301 from
  # *.substack.com/feed).
  def read_body
    URI.open(@source.feed_url, read_timeout: TIMEOUT, open_timeout: TIMEOUT, &:read)
  end

  def upsert_posts(entries)
    entries.first(MAX_ENTRIES).each do |entry|
      guid = entry.entry_id.presence || entry.url
      next if guid.blank?

      record = @source.substack_posts.find_or_initialize_by(guid: guid)
      record.title        = entry.title.presence
      record.url          = entry.url.presence
      record.author       = entry.author.presence
      record.published_at = entry.published
      record.summary      = summary_for(entry)
      record.save!
    end
  end

  def summary_for(entry)
    raw = entry.summary.presence || entry.content.presence || ""
    ActionController::Base.helpers.strip_tags(raw).gsub(/\s+/, " ").strip.truncate(500)
  end
end
