class RadarMonitoring < ApplicationRecord
  self.table_name = "radar_monitoring"

  validates :name, presence: true, uniqueness: true
  validates :priority, presence: true

  scope :ordered, -> { order(priority: :desc) }
end
