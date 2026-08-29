class ForecastUpdate < ApplicationRecord
  belongs_to :forecast
  has_and_belongs_to_many :users

  has_rich_text :short_text
  has_rich_text :discussion
  has_one_attached :image

  validates :forecast, presence: true
  validates :valid_until, presence: true

  STATUSES = %w[draft published archived].freeze

  validates :status, inclusion: { in: STATUSES }

  scope :ordered, -> { order(created_at: :desc) }
  scope :drafted, -> { where(status: "draft") }
  scope :published, -> { where(status: "published") }
  scope :archived, -> { where(status: "archived") }
  scope :expired, -> { where(valid_until: ..Time.current) }
  scope :active, -> { published.where("valid_until > ?", Time.current) }

  before_validation :set_defaults, on: :create
  before_save :archive_if_expired
  after_create :update_forecast_issue_date

  VALIDITY_HOURS = 6

  # Moves every published update whose validity has elapsed to the archived
  # status, so it stays available in the archive instead of going back to draft.
  def self.archive_expired!
    published.expired.update_all(status: "archived", updated_at: Time.current)
  end

  def title
    "Aggiornamento del #{I18n.l(created_at, format: :long)}"
  end

  def authors
    users.any? ? users.map { |user| "#{user.first_name} #{user.last_name}" }.to_sentence : "Staff PRETEMP"
  end

  def draft?
    status == "draft"
  end

  def published?
    status == "published"
  end

  def archived?
    status == "archived"
  end

  def active?
    published? && valid_until > Time.current
  end

  def expired?
    valid_until <= Time.current
  end

  def check_validity!
    update!(status: "archived") if published? && expired?
  end

  private

    def set_defaults
      self.status ||= "published"
      self.valid_until ||= VALIDITY_HOURS.hours.from_now
    end

    # An update that is saved (or re-saved) after its validity elapsed must not
    # stay published: it is archived so it never shows up on the linked forecast.
    def archive_if_expired
      self.status = "archived" if status == "published" && valid_until.present? && expired?
    end

    def update_forecast_issue_date
      forecast.update!(issue_date: Time.current)
    end
end
