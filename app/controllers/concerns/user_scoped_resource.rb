module UserScopedResource
  extend ActiveSupport::Concern

  private

  def current_user_scripts
    Script.joins(:idea).where(ideas: { user_id: current_user.id })
  end

  # Posts owned by the current user via EITHER path:
  #   scripted: post -> script -> idea -> user
  #   direct:   post -> idea -> user
  # We use two separate scoped queries and combine with OR to avoid the table
  # alias conflict that arises from joining ideas twice in a single query.
  def current_user_linkedin_posts
    via_script = LinkedinPost.joins(script: :idea).where(ideas: { user_id: current_user.id })
    via_idea   = LinkedinPost.joins(:idea).where(ideas: { user_id: current_user.id })
    LinkedinPost.where(id: via_script).or(LinkedinPost.where(id: via_idea))
  end

  def current_user_twitter_posts
    via_script = TwitterPost.joins(script: :idea).where(ideas: { user_id: current_user.id })
    via_idea   = TwitterPost.joins(:idea).where(ideas: { user_id: current_user.id })
    TwitterPost.where(id: via_script).or(TwitterPost.where(id: via_idea))
  end

  def current_user_instagram_posts
    via_script = InstagramPost.joins(script: :idea).where(ideas: { user_id: current_user.id })
    via_idea   = InstagramPost.joins(:idea).where(ideas: { user_id: current_user.id })
    InstagramPost.where(id: via_script).or(InstagramPost.where(id: via_idea))
  end
end
