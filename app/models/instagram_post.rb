class InstagramPost < ApplicationRecord
  belongs_to :script, optional: true
  belongs_to :idea,   optional: true
  has_many :chats, as: :chattable, dependent: :destroy

  validates :script_id, uniqueness: true, allow_nil: true
  validates :idea_id,   uniqueness: true, allow_nil: true
  validates :title, presence: true
  validate  :requires_exactly_one_parent

  def parent_idea = script&.idea || idea
  def user        = parent_idea&.user

  # This node's layer of the chat system prompt (see LlmContext).
  def system_prompt
    <<~TEXT.strip
      THIS INSTAGRAM POST
      Title: #{title}
      Hook: #{hook}
      Body: #{body}
    TEXT
  end

  private

  def requires_exactly_one_parent
    if script_id.present? == idea_id.present?
      errors.add(:base, "must belong to either a script or an idea, not both")
    end
  end
end
