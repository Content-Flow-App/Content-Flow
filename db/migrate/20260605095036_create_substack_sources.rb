class CreateSubstackSources < ActiveRecord::Migration[8.1]
  def change
    create_table :substack_sources do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name
      t.string :feed_url, null: false
      t.string :handle
      t.datetime :fetched_at

      t.timestamps
    end
  end
end
