class TwitterPost < ApplicationRecord
  belongs_to :script
  has_one :user, through: :script
  has_many :chats, as: :chattable, dependent: :destroy

  validates :script_id, uniqueness: true
  validates :title, presence: true

  # This node's layer of the chat system prompt (see LlmContext). It describes
  # the concrete post and is emitted only when a chat hangs off the post itself
  # (refine-time); during generation the chattable is the parent Script.
  def system_prompt
    <<~TEXT.strip
      THIS TWITTER POST
      Title: #{title}
      Hook: #{hook}
      Body: #{body}
    TEXT
  end
end
