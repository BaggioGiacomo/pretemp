class CreateForecasts < ActiveRecord::Migration[8.1]
  def change
    create_table :forecasts do |t|
      t.date :date, null: false
      t.text :status, null: false
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :forecasts, :date, unique: true
  end
end
