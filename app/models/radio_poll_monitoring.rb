class RadioPollMonitoring < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :priority, presence: true

  scope :ordered, -> { order(priority: :desc) }
end
