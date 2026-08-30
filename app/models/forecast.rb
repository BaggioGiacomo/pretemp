class Forecast < ApplicationRecord
  has_and_belongs_to_many :users
  has_many :forecast_updates, dependent: :destroy

  has_rich_text :summary
  has_rich_text :short_text
  has_rich_text :discussion
  has_one_attached :image

  validates :date, presence: true
  validates :summary, presence: true
  validates :image, presence: true

  scope :ordered, -> { order(date: :desc) }
  scope :published, -> { where(status: "published") }
  scope :drafted, -> { where(status: "draft") }
  scope :archived, -> { where(status: "archived") }
  scope :visible, -> { where(status: [ "published", "archived" ]) }
  scope :tendenze, -> { where(tendenza: true) }
  scope :published_tendenze, -> { where(status: "published", tendenza: true) }
  scope :previsioni, -> { where(tendenza: false) }
  scope :published_previsioni, -> { where(status: "published", tendenza: false) }

  before_validation :set_default_date, on: :create
  before_validation :set_default_status, on: :create
  before_validation :set_default_issue_date, on: :create
  before_save :draft_other_forecasts_for_same_date

  enum :risk_level, { basso: 0, medio: 1, alto: 2, molto_alto: 3 }, prefix: :risk

  DEFAULT_SUMMARY = "<div><!--block--><strong>PRETEMP è un gruppo di lavoro che si pone l'obiettivo di studiare e prevedere i fenomeni temporaleschi severi sul territorio italiano. PRETEMP NON EMETTE ALLERTE bensì previsioni probabilistiche sperimentali. PRETEMP inoltre svolge attività di raccolta di segnalazioni dei fenomeni severi avvenuti in collaborazione con l'associazione Meteonetwork e l'European Severe Storms Laboratory attraverso il database Storm Report al fine di verificare le previsioni emesse.&nbsp;<br><br>PER ALLERTAMENTO UFFICIALE AFFIDARSI SEMPRE AL DIPARTIMENTO DI PROTEZIONE CIVILE NAZIONALE.</strong></div>"

  def tendenza?
    self.tendenza == true
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

  def label
    tendenza? ? "Tendenza" : "Previsione"
  end

  def title
    "#{label} per il #{I18n.l(date, format: "%-d %B %Y")}"
  end

  # If there are any users, return their first name and second name as a sentence, otherwise return "Staff PRETEMP"
  def authors
    users.any? ? users.map { |user| "#{user.first_name} #{user.last_name}" }.to_sentence : "Staff PRETEMP"
  end

  def active_update
    forecast_updates.active.ordered.first
  end

  # Updates the public site may show, newest first. Filtered in Ruby so that a
  # preloaded association (list views) is reused instead of firing one query
  # per forecast.
  def visible_updates
    forecast_updates.to_a
                    .select { |forecast_update| ForecastUpdate::VISIBLE_STATUSES.include?(forecast_update.status) }
                    .sort_by(&:created_at)
                    .reverse
  end

  def self.previsione_for(date)
    published_previsioni.find_by(date: date)
  end

  # Forecast to highlight in the home page hero: always a previsione, never a
  # tendenza (those get their own banner above the hero).
  def self.featured_previsione
    previsione_for(Date.tomorrow) || previsione_for(Date.current) || published_previsioni.ordered.first
  end

  # Nearest tendenza still ahead of us, shown in the home page banner.
  def self.upcoming_tendenza
    published_tendenze.where(date: Date.current..).order(:date).first
  end

  private

    def set_default_date
      self.date ||= Date.today
    end

    def set_default_status
      self.status ||= "draft"
    end

    def set_default_issue_date
      self.issue_date ||= Time.current
    end

    # When this forecast becomes the published one for its date, mark any
    # other previously-published forecasts for the same date as drafts.
    def draft_other_forecasts_for_same_date
      return unless status == "published"
      return if date.nil?

      scope = self.class.where(date: date, status: "published")
      scope = scope.where.not(id: id) if persisted?
      scope.update_all(status: "archived", updated_at: Time.current)
    end
end
