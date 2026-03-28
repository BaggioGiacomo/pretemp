class AddWeatherStationMonitoringTable < ActiveRecord::Migration[8.1]
  def change
    create_table :weather_station_monitorings do |t|
      t.string :name, null: false
      t.string :description
      t.string :url
      t.integer :priority, null: false, default: 0

      t.timestamps
    end

    add_index :weather_station_monitorings, :name, unique: true
  end
end
