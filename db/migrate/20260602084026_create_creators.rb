class CreateCreators < ActiveRecord::Migration[8.1]
  def change
    create_table :creators do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name
      t.string :topic
      t.string :goal
      t.string :audience

      t.timestamps
    end
  end
end
