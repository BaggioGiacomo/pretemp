class AddTendenzaToForecasts < ActiveRecord::Migration[8.1]
  def change
    add_column :forecasts, :tendenza, :boolean, default: false, null: false
  end
end
