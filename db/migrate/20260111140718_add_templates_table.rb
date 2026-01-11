class AddTemplatesTable < ActiveRecord::Migration[8.1]
  def change
    create_table :templates do |t|
      t.string :name, null: false
      t.string :url

      t.timestamps
    end
  end
end
