class AddConfirmableToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :confirmation_token, :string
    add_index :users, :confirmation_token, unique: true
    add_column :users, :confirmed_at, :datetime
    add_column :users, :confirmation_sent_at, :datetime
    add_column :users, :unconfirmed_email, :string

    reversible do |dir|
      dir.up do
        execute "UPDATE users SET confirmed_at = NOW() WHERE confirmed_at IS NULL"
      end
    end
  end
end
