class SubstackPost < ApplicationRecord
  belongs_to :substack_source
  has_one :user, through: :substack_source

  validates :guid, presence: true, uniqueness: { scope: :substack_source_id }

  default_scope { order(published_at: :desc) }
end
