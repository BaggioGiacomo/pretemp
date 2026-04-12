class ChangeForecastUpdateStatusDefaultToPublished < ActiveRecord::Migration[8.1]
  def change
    change_column_default :forecast_updates, :status, from: "draft", to: "published"
  end
end
