class AddTemplateCategoriesTable < ActiveRecord::Migration[8.1]
  def change
    create_table :template_categories do |t|
      t.string :name, null: false

      t.timestamps
    end
  end
end
