class CreateForecastsUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :forecasts_users do |t|
      t.references :forecast, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :forecasts_users, [ :forecast_id, :user_id ], unique: true

    remove_reference :forecasts, :user, foreign_key: true
  end
end
