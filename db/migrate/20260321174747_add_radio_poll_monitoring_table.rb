class AddRadioPollMonitoringTable < ActiveRecord::Migration[8.1]
  def change
    create_table :radio_poll_monitorings do |t|
      t.string :name, null: false
      t.string :description
      t.string :url
      t.integer :priority, null: false, default: 0

      t.timestamps
    end

    add_index :radio_poll_monitorings, :name, unique: true
  end
end
