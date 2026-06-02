class CreateLinkedinPosts < ActiveRecord::Migration[8.1]
  def change
    create_table :linkedin_posts do |t|
      t.references :script, null: false, foreign_key: true
      t.string :title
      t.string :hook
      t.text :body

      t.timestamps
    end
  end
end
