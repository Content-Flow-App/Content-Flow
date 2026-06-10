class Idea < ApplicationRecord
  belongs_to :user
  has_many :scripts, dependent: :destroy

  # Direct posts: idea → post (no script). Each platform type allows at most one
  # direct post per idea, enforced by the uniqueness validation on idea_id in
  # each post model.
  has_one :linkedin_post,  dependent: :destroy
  has_one :twitter_post,   dependent: :destroy
  has_one :instagram_post, dependent: :destroy

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
