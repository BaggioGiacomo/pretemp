class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :sent_invitations, class_name: "Invitation", foreign_key: :invited_by_id

  normalizes :email_address, with: ->(e) { e.strip.downcase }
end
