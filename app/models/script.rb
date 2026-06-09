class Script < ApplicationRecord
  belongs_to :idea
  has_one :user, through: :idea
  has_one :linkedin_post, dependent: :destroy
  has_one :twitter_post, dependent: :destroy
  has_one :instagram_post, dependent: :destroy
  has_many :chats, as: :chattable, dependent: :destroy

  validates :title, presence: true

  # This node's layer of the chat system prompt (see LlmContext). When the
  # creator has supplied `custom_instructions` for this script, they are appended
  # as a SCRIPT INSTRUCTIONS block.
  def system_prompt
    text = <<~TEXT.strip
      PARENT SCRIPT
      Title: #{title}
      Style: #{style}
      Length: #{length}
      Description: #{description}
    TEXT

    if custom_instructions.present?
      text + "\n\nSCRIPT INSTRUCTIONS\n#{custom_instructions}"
    else
      text
    end
  end
end
