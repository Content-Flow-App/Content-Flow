class CreateSubstackPosts < ActiveRecord::Migration[8.1]
  def change
    create_table :substack_posts do |t|
      t.references :substack_source, null: false, foreign_key: true
      t.string :title
      t.string :url
      t.text :summary
      t.string :author
      t.datetime :published_at
      t.string :guid, null: false

      t.timestamps
    end

    add_index :substack_posts, [ :substack_source_id, :guid ], unique: true
  end
end
