class AddDirectIdeaToPostTables < ActiveRecord::Migration[8.1]
  def change
    # Allow posts to be created directly from an idea (no script in between).
    # script_id becomes optional; idea_id is the new direct-path FK.
    # A post must have exactly one of these set — enforced at the model layer.
    [ :linkedin_posts, :twitter_posts, :instagram_posts ].each do |table|
      add_reference table, :idea, null: true, foreign_key: true, index: true
      change_column_null table, :script_id, true
    end
  end
end
