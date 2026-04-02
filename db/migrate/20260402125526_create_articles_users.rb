class CreateArticlesUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :articles_users do |t|
      t.references :article, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :articles_users, [ :article_id, :user_id ], unique: true
  end
end
