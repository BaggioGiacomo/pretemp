class DidatticaSection < ApplicationRecord
  has_many :didattica_items, -> { ordered }, dependent: :destroy

  validates :name, presence: true
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validate  :position_must_be_free

  scope :ordered, -> { order(:position, :id) }

  # Lowest non-negative integer not used by any other section.
  def self.next_free_position
    taken = where.not(position: nil).pluck(:position).to_set
    pos = 0
    pos += 1 while taken.include?(pos)
    pos
  end

  # Nearest free position to `target`, ignoring this record.
  def nearest_free_position(target = position)
    target = target.to_i
    taken = self.class.where.not(id: id).where.not(position: nil).pluck(:position).to_set
    return target unless taken.include?(target)

    offset = 1
    loop do
      down = target - offset
      return down if down >= 0 && !taken.include?(down)
      up = target + offset
      return up unless taken.include?(up)
      offset += 1
    end
  end

  private

    def position_must_be_free
      return if position.blank?

      if self.class.where.not(id: id).exists?(position: position)
        errors.add(:position, "è già occupata. La posizione libera più vicina è #{nearest_free_position}.")
      end
    end
end
