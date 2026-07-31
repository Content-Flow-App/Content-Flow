class RepointNonAnthropicChatsToDefaultModel < ActiveRecord::Migration[8.1]
  # GitHub Models was dropped entirely (issue #45) — see
  # config/initializers/ruby_llm.rb. Any chat still pointing at a
  # GitHub-Models-routed model (gpt-4o, gpt-4o-mini, gpt-4.1, the mistral-ai/
  # and deepseek/ rows) now has no credentials configured for its provider at
  # all, so completing it raises RubyLLM::ConfigurationError — a class that
  # (unlike RubyLLM::Error) ChatResponseJob's rescues don't catch, so the
  # chat would silently stop responding instead of showing an error. This is
  # not hypothetical: it's exactly what happened to production chat 168
  # (the chat that surfaced issue #45).
  #
  # Reassign every such chat to the new default, claude-sonnet-5, so no
  # existing chat is left pointing at an unconfigured provider. Scoped to
  # "not anthropic" rather than the specific removed model ids, since the
  # actual failure condition is "provider has no credentials," which today
  # means anything other than anthropic.
  def up
    default_model_id = Model.find_by!(model_id: "claude-sonnet-5").id

    execute <<~SQL
      UPDATE chats
      SET model_id = #{default_model_id}
      FROM models
      WHERE chats.model_id = models.id
        AND models.provider <> 'anthropic'
    SQL
  end

  def down
    # Irreversible: the original per-chat model_id is not recoverable once
    # overwritten, and re-pointing back at now-unconfigured GitHub Models
    # rows would just reintroduce the bug this migration fixes.
    raise ActiveRecord::IrreversibleMigration
  end
end
