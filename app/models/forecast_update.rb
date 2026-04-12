class ForecastUpdate < ApplicationRecord
  belongs_to :forecast
  has_and_belongs_to_many :users

  has_rich_text :body
  has_one_attached :image

  validates :body, presence: true
  validates :forecast, presence: true
  validates :valid_until, presence: true

  scope :ordered, -> { order(created_at: :desc) }

  before_validation :set_defaults, on: :create

  VALIDITY_HOURS = 6

  def title
    "Aggiornamento del #{I18n.l(created_at, format: :long)}"
  end

  def authors
    users.any? ? users.map { |user| "#{user.first_name} #{user.last_name}" }.to_sentence : "Staff PRETEMP"
  end

  def active?
    status == "published" && valid_until > Time.current
  end

  def expired?
    valid_until <= Time.current
  end

  def check_validity!
    update!(status: "draft") if status == "published" && expired?
  end

  private

    def set_defaults
      self.status ||= "draft"
      self.valid_until ||= VALIDITY_HOURS.hours.from_now
    end
end
