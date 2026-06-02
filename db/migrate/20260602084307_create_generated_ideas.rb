class CreateGeneratedIdeas < ActiveRecord::Migration[8.1]
  def change
    create_table :generated_ideas do |t|
      t.references :user, null: false, foreign_key: true
      t.references :idea, null: false, foreign_key: true
      t.string :topic
      t.string :title
      t.text :description

      t.timestamps
    end
  end
end
