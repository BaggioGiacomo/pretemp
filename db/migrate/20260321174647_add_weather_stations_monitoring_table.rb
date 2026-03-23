class AddWeatherStationsMonitoringTable < ActiveRecord::Migration[8.1]
  def change
    create_table :weather_stations_monitoring do |t|
      t.string :name, null: false
      t.string :description
      t.string :url
      t.integer :priority, null: false, default: 0

      t.timestamps
    end

    add_index :weather_stations_monitoring, :name, unique: true
  end
end
