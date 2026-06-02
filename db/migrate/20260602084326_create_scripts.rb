class CreateScripts < ActiveRecord::Migration[8.1]
  def change
    create_table :scripts do |t|
      t.references :idea, null: false, foreign_key: true
      t.string :length
      t.string :style
      t.string :title
      t.text :description
      t.text :system_prompt

      t.timestamps
    end
  end
end
