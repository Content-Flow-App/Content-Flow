class FetchSubstackSourceJob < ApplicationJob
  queue_as :default

  def perform(substack_source_id)
    source = SubstackSource.find_by(id: substack_source_id)
    return unless source

    SubstackFetchService.call(source)
    broadcast_feed(source.user)
  end

  private

  # Pushes the re-rendered feed over the user's Turbo Stream so new posts show
  # up without a reload. Anyone on /substack_posts is subscribed via the
  # turbo_stream_from tag in the index view; if nobody is, the broadcast is a
  # no-op. We broadcast after failures too: a failed fetch records
  # `fetch_error`, and the feed's empty state explains it to the user.
  def broadcast_feed(user)
    Turbo::StreamsChannel.broadcast_replace_to(
      "substack_feed_#{user.id}",
      target: "substack_feed",
      partial: "substack_posts/feed",
      locals: {
        posts:   user.substack_feed,
        sources: user.substack_sources.order(created_at: :desc)
      }
    )
  end
end
