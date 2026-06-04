class Idea < ApplicationRecord
  belongs_to :user
<<<<<<< HEAD
  has_many :scripts, dependent: :destroy
  validates :title, presence: true
=======
  has_many :chats, as: :chattable, dependent: :destroy
>>>>>>> 4ac9e9d2e540c2ac030b8312b56a594c692f80f1
end
