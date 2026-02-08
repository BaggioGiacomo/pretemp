class CreateInvitations < ActiveRecord::Migration[8.1]
  def change
    create_table :invitations do |t|
      t.string :email, null: false
      t.string :token, null: false
      t.datetime :accepted_at
      t.datetime :expires_at, null: false
      t.integer :invited_by_id

      t.timestamps
    end

    add_index :invitations, :token, unique: true
    add_index :invitations, :email
  end
end
