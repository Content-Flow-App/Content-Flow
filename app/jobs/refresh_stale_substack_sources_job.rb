class RefreshStaleSubstackSourcesJob < ApplicationJob
  queue_as :default

  # Runs on a schedule (see config/recurring.yml) so feeds stay current without
  # anyone having to hit the manual "refresh" button. Mirrors the staleness
  # check in SubstackPostsController#refresh, just across every user's sources.
  def perform
    SubstackSource.find_each do |source|
      FetchSubstackSourceJob.perform_later(source.id) if source.stale?
    end
  end
end
