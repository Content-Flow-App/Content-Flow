# SubstackPostsController renders the aggregated feed across all of the user's
# Substack sources, and provides a refresh action to re-fetch them.
#
# Routes (from `resources :substack_posts, only: [:index]` + collection block):
#   GET  /substack_posts          → #index   (substack_posts_path)
#   POST /substack_posts/refresh  → #refresh (refresh_substack_posts_path)
#
# **Why `refresh` is a collection route, not a member route:**
# A member route acts on one specific record (it puts :id in the URL, e.g.
# `/substack_posts/42/refresh`). A collection route acts on the whole group
# (no :id). Refreshing fires a job for *all* of the user's sources together,
# so the collection route is the right fit.
class SubstackPostsController < ApplicationController
  def index
    @posts   = current_user.substack_feed
    @sources = current_user.substack_sources.order(created_at: :desc)
  end

  def refresh
    stale_sources = current_user.substack_sources.select(&:stale?)
    stale_sources.each { |source| FetchSubstackSourceJob.perform_later(source.id) }

    # Sources inside the 1-hour cooldown are skipped, so be honest about
    # whether anything was actually enqueued instead of always claiming
    # "refreshing".
    notice =
      if stale_sources.any?
        "Refreshing #{helpers.pluralize(stale_sources.size, 'source')} — new posts will appear in a moment."
      else
        "Your feed is already up to date — sources refresh at most once an hour."
      end
    redirect_to substack_posts_path, notice: notice
  end
end
