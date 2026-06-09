class RenameScriptSystemPromptToCustomInstructions < ActiveRecord::Migration[8.1]
  def change
    rename_column :scripts, :system_prompt, :custom_instructions
  end
end
