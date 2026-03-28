class RadarMonitoring < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :priority, presence: true

  scope :ordered, -> { order(priority: :asc) }
end
