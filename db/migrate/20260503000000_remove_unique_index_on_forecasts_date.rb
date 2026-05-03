class RemoveUniqueIndexOnForecastsDate < ActiveRecord::Migration[8.0]
  def change
    remove_index :forecasts, name: "index_forecasts_on_date"
    add_index :forecasts, :date
  end
end
