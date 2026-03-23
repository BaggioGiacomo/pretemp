class AddRadarMonitoringTable < ActiveRecord::Migration[8.1]
  def change
    create_table :radar_monitoring do |t|
      t.string :name, null: false
      t.string :description
      t.string :url
      t.integer :priority, null: false, default: 0

      t.timestamps
    end

    add_index :radar_monitoring, :name, unique: true
  end
end
