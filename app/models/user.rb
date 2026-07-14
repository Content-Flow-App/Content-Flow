class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable

  validate :password_complexity

  has_one :creator
  has_many :ideas, dependent: :destroy
  has_many :substack_sources, dependent: :destroy
  has_many :substack_posts, through: :substack_sources

  # The aggregated idea feed: every post across the user's sources, newest
  # first. Lives here because two callers must render the identical feed —
  # SubstackPostsController#index and FetchSubstackSourceJob's live broadcast.
  def substack_feed
    substack_posts.includes(substack_source: :user).order(published_at: :desc)
  end

  # as: :chattable tells Rails the foreign key lives in the polymorphic pair
  # chattable_type/chattable_id on chats (not a conventional user_id). The User
  # is the single top-level chat owner; brand context is reached via the
  # creator. dependent: :destroy clears a user's chats when the user is removed.
  has_many :chats, as: :chattable, dependent: :destroy

  # The chats this user actually owns (via chats.user_id), for authorization —
  # distinct from #chats above, which is the polymorphic "chats where I am the
  # chattable subject" relation. A chat's owner and its chattable are
  # independent: owned_chats covers every chat the user created, including
  # standalone ones with no chattable at all.
  has_many :owned_chats, class_name: "Chat", foreign_key: :user_id, dependent: :destroy

  # A User is the top-level chat node; its system-prompt layer is the creator
  # profile, reached through the association. Returns nil when there is no
  # creator yet, so LlmContext emits no instructions for a brand-less owner.
  def system_prompt
    creator&.system_prompt
  end

  def onboarding_complete?
    next_onboarding_step == :done
  end

  def next_onboarding_step
    return :creator unless creator.present?
    return :idea    unless ideas.any?
    return :script  unless Script.where(idea: ideas).exists?

    # A post satisfies the onboarding step whether it came via a script or was
    # created directly from an idea (dual-flow). Check both paths.
    has_post = LinkedinPost.where(script: Script.where(idea: ideas)).exists? ||
               LinkedinPost.where(idea: ideas).exists?
    return :post unless has_post

    :done
  end

  private

  def password_complexity
    return if password.blank?

    errors.add(:password, "must include at least one number") unless password.match?(/\d/)
    errors.add(:password, "must include at least one symbol") unless password.match?(/[^a-zA-Z\d\s]/)
  end
end
