class AddRiskLevelToForecast < ActiveRecord::Migration[8.1]
  def change
    add_column :forecasts, :risk_level, :integer, null: false, default: 0
  end
end
