class AddDescriptionToTemplateCategory < ActiveRecord::Migration[8.1]
  def change
    add_column :template_categories, :description, :text
  end
end
