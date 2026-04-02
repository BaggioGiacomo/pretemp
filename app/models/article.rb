class Article < ApplicationRecord
  has_rich_text :body

  validates :title, presence: true
  validates :body, presence: true

  scope :published, -> { where(published: true) }
  scope :ordered, -> { order(created_at: :desc) }
end
