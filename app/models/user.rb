class User < ApplicationRecord
  has_secure_password
  has_one_attached :profile_image
  has_one_attached :curriculum
  has_rich_text :description
  has_many :sessions, dependent: :destroy
  has_many :sent_invitations, class_name: "Invitation", foreign_key: :invited_by_id
  has_and_belongs_to_many :forecasts
  has_and_belongs_to_many :articles

  validates :first_name, presence: true
  validates :last_name, presence: true

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  generates_token_for :password_reset, expires_in: 48.hours do
    password_salt&.last(10)
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def username
    first_name.present? ? full_name : email_address
  end
end
