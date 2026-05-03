class Forecast < ApplicationRecord
  has_and_belongs_to_many :users
  has_many :forecast_updates, dependent: :destroy

  has_rich_text :summary
  has_rich_text :body
  has_one_attached :image

  validates :date, presence: true
  validates :summary, presence: true
  validates :body, presence: true
  validates :image, presence: true

  scope :ordered, -> { order(date: :desc) }
  scope :published, -> { where(status: "published") }
  scope :drafted, -> { where(status: "draft") }

  before_validation :set_default_date, on: :create
  before_validation :set_default_status, on: :create
  before_save :draft_other_forecasts_for_same_date

  enum :risk_level, { basso: 0, medio: 1, alto: 2, molto_alto: 3 }, prefix: :risk

  DEFAULT_SUMMARY = "<div><!--block--><strong>PRETEMP è un gruppo di lavoro che si pone l'obiettivo di studiare e prevedere i fenomeni temporaleschi severi sul territorio italiano. PRETEMP NON EMETTE ALLERTE bensì previsioni probabilistiche sperimentali. PRETEMP inoltre svolge attività di raccolta di segnalazioni dei fenomeni severi avvenuti in collaborazione con l'associazione Meteonetwork e l'European Severe Storms Laboratory attraverso il database Storm Report al fine di verificare le previsioni emesse.&nbsp;<br><br>PER ALLERTAMENTO UFFICIALE AFFIDARSI SEMPRE AL DIPARTIMENTO DI PROTEZIONE CIVILE NAZIONALE.</strong></div>"

  # A forecast is a "Tendenza" if, at the time it was created, the target date
  # was 2 or more days after the creation date. Otherwise it is a "Previsione".
  # The label is frozen at creation time and does not change as days pass.
  def tendenza?
    return false if date.nil?
    reference = (created_at || Time.current).to_date
    (date - reference).to_i >= 2
  end

  def draft?
    status == "draft"
  end

  def published?
    status == "published"
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

  def body_preview
    body.to_plain_text.gsub("TESTO BREVE", "")
  end

  def active_update
    forecast_updates.where(status: "published").where("valid_until > ?", Time.current).order(created_at: :desc).first
  end

  def self.today
    published.find_by(date: Date.today)
  end

  private

    def set_default_date
      self.date ||= Date.today
    end

    def set_default_status
      self.status ||= "draft"
    end

    # When this forecast becomes the published one for its date, mark any
    # other previously-published forecasts for the same date as drafts.
    def draft_other_forecasts_for_same_date
      return unless status == "published"
      return if date.nil?

      scope = self.class.where(date: date, status: "published")
      scope = scope.where.not(id: id) if persisted?
      scope.update_all(status: "draft", updated_at: Time.current)
    end
end
