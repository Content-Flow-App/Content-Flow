class AddUserToChats < ActiveRecord::Migration[8.1]
  def change
    add_reference :chats, :user, foreign_key: true, index: true

    reversible do |dir|
      dir.up do
        # Backfill user_id from the existing chattable ancestry chain, one
        # path per chattable_type. Rows with chattable_id NULL (standalone
        # chats) have no signal for who created them and are deliberately
        # left with user_id: NULL — see openspec/changes/scope-chat-ownership/design.md.
        execute <<~SQL
          UPDATE chats SET user_id = chattable_id
          WHERE chattable_type = 'User'
        SQL

        execute <<~SQL
          UPDATE chats SET user_id = ideas.user_id
          FROM ideas
          WHERE chats.chattable_type = 'Idea' AND chats.chattable_id = ideas.id
        SQL

        execute <<~SQL
          UPDATE chats SET user_id = ideas.user_id
          FROM scripts JOIN ideas ON ideas.id = scripts.idea_id
          WHERE chats.chattable_type = 'Script' AND chats.chattable_id = scripts.id
        SQL

        # LinkedinPost/TwitterPost/InstagramPost: post -> (script -> idea) or
        # (idea) -> user, mirroring each post model's parent_idea/user methods.
        { "LinkedinPost" => "linkedin_posts",
          "TwitterPost" => "twitter_posts",
          "InstagramPost" => "instagram_posts" }.each do |chattable_type, table|
          execute <<~SQL
            UPDATE chats SET user_id = ideas.user_id
            FROM #{table} AS posts
            LEFT JOIN scripts ON scripts.id = posts.script_id
            LEFT JOIN ideas ON ideas.id = COALESCE(scripts.idea_id, posts.idea_id)
            WHERE chats.chattable_type = '#{chattable_type}' AND chats.chattable_id = posts.id
          SQL
        end
      end
    end
  end
end
