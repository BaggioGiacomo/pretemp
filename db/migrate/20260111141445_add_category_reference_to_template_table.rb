class AddCategoryReferenceToTemplateTable < ActiveRecord::Migration[8.1]
  def change
    add_reference :templates, :template_category, null: true, foreign_key: true
  end
end
