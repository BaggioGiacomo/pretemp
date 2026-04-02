class Article < ApplicationRecord
  has_and_belongs_to_many :users
  has_rich_text :body

  validates :title, presence: true
  validates :body, presence: true

  scope :published, -> { where(published: true) }
  scope :ordered, -> { order(created_at: :desc) }

  def authors
    users.any? ? users.map(&:email_address).join(", ") : "Staff PRETEMP"
  end

  def body_preview
    body.to_plain_text.truncate(200)
  end
end
