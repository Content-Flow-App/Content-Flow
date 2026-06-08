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
    @posts   = current_user.substack_posts
                            .includes(substack_source: :user)
                            .order(published_at: :desc)
    @sources = current_user.substack_sources.order(created_at: :desc)
  end

  def refresh
    current_user.substack_sources.each do |source|
      FetchSubstackSourceJob.perform_later(source.id) if source.stale?
    end
    redirect_to substack_posts_path, notice: "Refreshing sources — check back in a moment."
  end
end
