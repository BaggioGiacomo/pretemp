class Forecast < ApplicationRecord
  has_and_belongs_to_many :users
  has_many :forecast_updates, dependent: :destroy

  has_rich_text :summary
  has_rich_text :body
  has_one_attached :image

  validates :date, presence: true, uniqueness: true
  validates :summary, presence: true
  validates :body, presence: true
  validates :image, presence: true

  scope :ordered, -> { order(date: :desc) }

  before_validation :set_default_date, on: :create
  before_validation :set_default_status, on: :create

  enum :risk_level, { basso: 0, medio: 1, alto: 2, molto_alto: 3 }, prefix: :risk

  DEFAULT_SUMMARY = "<div><!--block--><strong>PRETEMP è un gruppo di lavoro che si pone l'obiettivo di studiare e prevedere i fenomeni temporaleschi severi sul territorio italiano. PRETEMP NON EMETTE ALLERTE bensì previsioni probabilistiche sperimentali. PRETEMP inoltre svolge attività di raccolta di segnalazioni dei fenomeni severi avvenuti in collaborazione con l'associazione Meteonetwork e l'European Severe Storms Laboratory attraverso il database Storm Report al fine di verificare le previsioni emesse.&nbsp;<br><br>PER ALLERTAMENTO UFFICIALE AFFIDARSI SEMPRE AL DIPARTIMENTO DI PROTEZIONE CIVILE NAZIONALE.</strong></div>"

  def tendenza?
    date == Date.tomorrow
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
    find_by(date: Date.today)
  end

  private

    def set_default_date
      self.date ||= Date.today
    end

    def set_default_status
      self.status ||= "draft"
    end
end
