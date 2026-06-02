class CreateIdeas < ActiveRecord::Migration[8.1]
  def change
    create_table :ideas do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title
      t.text :description
      t.string :topic

      t.timestamps
    end
  end
end
