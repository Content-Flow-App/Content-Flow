module UserScopedResource
  extend ActiveSupport::Concern

  private

  def current_user_scripts
    Script.joins(:idea).where(ideas: { user_id: current_user.id })
  end

  # LinkedinPosts the current user owns. Ownership runs two hops up the chain
  # (post -> script -> idea -> user), so we join through both and filter on the
  # idea's user_id. Used to authorize a post by re-resolving it through a
  # user-scoped relation (a `.find` here raises RecordNotFound -> 404 for a
  # non-owner) instead of trusting an id from the request.
  def current_user_linkedin_posts
    LinkedinPost.joins(script: :idea).where(ideas: { user_id: current_user.id })
  end
end
