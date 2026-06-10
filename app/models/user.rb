class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_one :creator
  has_many :ideas, dependent: :destroy
  has_many :substack_sources, dependent: :destroy
  has_many :substack_posts, through: :substack_sources

  # as: :chattable tells Rails the foreign key lives in the polymorphic pair
  # chattable_type/chattable_id on chats (not a conventional user_id). The User
  # is the single top-level chat owner; brand context is reached via the
  # creator. dependent: :destroy clears a user's chats when the user is removed.
  has_many :chats, as: :chattable, dependent: :destroy

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
end
