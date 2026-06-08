class SubstackSource < ApplicationRecord
  belongs_to :user
  has_many :substack_posts, dependent: :destroy

  validates :feed_url, presence: true, uniqueness: { scope: :user_id }

  # Normalise whatever the user types (handle or full URL) into the canonical
  # /feed path. Examples:
  #   "lennysnewsletter"                -> "https://lennysnewsletter.substack.com/feed"
  #   "lennysnewsletter.substack.com"   -> "https://lennysnewsletter.substack.com/feed"
  #   "https://…substack.com/"         -> "https://…substack.com/feed"
  before_validation :normalize_feed_url

  # Never re-fetch a source that was refreshed within the last hour.
  REFRESH_COOLDOWN = 1.hour

  def stale?
    fetched_at.nil? || fetched_at < REFRESH_COOLDOWN.ago
  end

  private

  def normalize_feed_url
    return if feed_url.blank?

    input = feed_url.strip

    # Bare handle (no dots, no slashes) → full Substack feed URL
    if input.match?(/\A[a-z0-9_-]+\z/i)
      self.feed_url = "https://#{input}.substack.com/feed"
      self.handle ||= input
      return
    end

    # Strip leading "https?://" if present for uniform processing
    without_scheme = input.sub(%r{\Ahttps?://}, "")

    # Ensure it ends with /feed
    without_scheme = without_scheme.chomp("/").sub(%r{/feed\z}, "")
    self.feed_url = "https://#{without_scheme}/feed"

    # Extract the handle (subdomain) if we haven't set it yet
    self.handle ||= without_scheme[/\A([^.]+)\.substack\.com/, 1]
  end
end
