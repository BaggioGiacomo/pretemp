class ChangeRiskLevelNullableOnForecasts < ActiveRecord::Migration[8.1]
  def change
    change_column :forecasts, :risk_level, :integer, null: true, default: nil
  end
end
