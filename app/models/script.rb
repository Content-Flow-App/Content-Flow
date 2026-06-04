class Script < ApplicationRecord
  belongs_to :idea
  has_one :user, through: :idea
  has_many :chats, as: :chattable, dependent: :destroy

  validates :title, presence: true
end
