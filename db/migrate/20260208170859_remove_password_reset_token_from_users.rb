class RemovePasswordResetTokenFromUsers < ActiveRecord::Migration[8.1]
  def change
    remove_column :users, :password_reset_token, :string
    remove_column :users, :password_reset_token_expires_at, :datetime
  end
end
