class Creator < ApplicationRecord
  belongs_to :user
  validates :name, :topic, :goal, :audience, presence: true

  # The brand layer of the chat system prompt. `LlmContext` assembles each chat
  # node's #system_prompt into the full instruction; this is the topmost layer,
  # reached from a chat via `user.creator` (a Creator owns no chats itself).
  def system_prompt
    <<~TEXT.strip
      CREATOR PROFILE
      Name: #{name}
      Topic: #{topic}
      Goal: #{goal}
      Audience: #{audience}
    TEXT
  end
end
