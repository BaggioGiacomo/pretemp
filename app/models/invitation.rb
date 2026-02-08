class Invitation < ApplicationRecord
  belongs_to :invited_by, class_name: "User", optional: true

  normalizes :email, with: ->(e) { e.strip.downcase }

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :token, presence: true, uniqueness: true
  validate :email_not_already_registered, on: :create

  before_validation :generate_token, on: :create
  before_validation :set_expiration, on: :create

  scope :pending, -> { where(accepted_at: nil).where("expires_at > ?", Time.current) }

  def expired?
    expires_at < Time.current
  end

  def accepted?
    accepted_at.present?
  end

  def acceptable?
    !expired? && !accepted?
  end

  def accept!
    update!(accepted_at: Time.current)
  end

  private

  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(32)
  end

  def set_expiration
    self.expires_at ||= 48.hours.from_now
  end

  def email_not_already_registered
    if User.exists?(email_address: email)
      errors.add(:email, "is already registered")
    end
  end
end
