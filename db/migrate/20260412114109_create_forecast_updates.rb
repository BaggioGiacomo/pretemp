class CreateForecastUpdates < ActiveRecord::Migration[8.1]
  def change
    create_table :forecast_updates do |t|
      t.references :forecast, null: false, foreign_key: true
      t.text :status, null: false, default: "draft"
      t.datetime :valid_until, null: false

      t.timestamps
    end

    create_table :forecast_updates_users do |t|
      t.references :forecast_update, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :forecast_updates_users, [ :forecast_update_id, :user_id ], unique: true
  end
end
