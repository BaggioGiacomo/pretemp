class DidatticaItem < ApplicationRecord
  belongs_to :didattica_section

  has_one_attached :pdf

  attr_accessor :remove_pdf

  validates :title, presence: true
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validate  :url_or_pdf_present
  validate  :position_must_be_free

  scope :ordered, -> { order(:position, :id) }

  # Lowest non-negative integer not used by any other item in the same section.
  def self.next_free_position(section)
    taken = where(didattica_section_id: section.id).where.not(position: nil).pluck(:position).to_set
    pos = 0
    pos += 1 while taken.include?(pos)
    pos
  end

  # Nearest free position to `target`, ignoring this record.
  def nearest_free_position(target = position)
    target = target.to_i
    taken = self.class.where(didattica_section_id: didattica_section_id)
                      .where.not(id: id)
                      .where.not(position: nil)
                      .pluck(:position).to_set
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

  # Returns the URL the public page should link to: the attached PDF blob URL,
  # or the manually-entered URL.
  def link_url
    if pdf.attached?
      Rails.application.routes.url_helpers.rails_blob_path(pdf, only_path: true)
    else
      url
    end
  end

  # True when the link points to a PDF (attached file or .pdf URL).
  def pdf?
    pdf.attached? || url.to_s.downcase.end_with?(".pdf")
  end

  # External link if URL is absolute (or attached PDF, which we open in a new tab).
  def external?
    pdf.attached? || url.to_s.match?(/\Ahttps?:\/\//i)
  end

  private

    def url_or_pdf_present
      return if pdf.attached? || url.present?

      errors.add(:base, "Devi indicare un URL oppure caricare un PDF.")
    end

    def position_must_be_free
      return if position.blank? || didattica_section_id.blank?

      scope = self.class.where(didattica_section_id: didattica_section_id).where.not(id: id)
      if scope.exists?(position: position)
        errors.add(:position, "è già occupata. La posizione libera più vicina è #{nearest_free_position}.")
      end
    end
end
