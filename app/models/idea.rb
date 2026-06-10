class Idea < ApplicationRecord
  belongs_to :user
  has_many :scripts, dependent: :destroy
  validates :title, presence: true
  has_many :chats, as: :chattable, dependent: :destroy

  # This node's layer of the chat system prompt (see LlmContext).
  def system_prompt
    <<~TEXT.strip
      **PARENT IDEA**
      Title: #{title}
      Topic: #{topic}
      Description: #{description}
    TEXT
  end
end
