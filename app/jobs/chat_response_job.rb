class ChatResponseJob < ApplicationJob
  # The user's message is persisted by the controller *before* this job is
  # enqueued (see ChatsController/MessagesController#create), so the chat page
  # renders it immediately on load. That avoids the first-message race: the
  # previous `chat.ask(content)` created the user message inside the job and
  # broadcast it, which could fire before the browser had subscribed to the
  # chat's Turbo Stream — so the opening message was missed until a reload.
  #
  # Here we only generate the assistant reply with `complete`, streaming each
  # chunk into the assistant message's content target. That broadcast happens
  # after the LLM responds (seconds later), by which point the subscription is
  # reliably established.
  def perform(chat_id)
    chat = Chat.find(chat_id)

    # Suppress the auto-broadcasts that `broadcasts_to` fires on message create
    # and update. On a new chat the `:async` adapter runs this job before the
    # browser completes its redirect + WebSocket handshake, so those broadcasts
    # land in SolidCable before the client subscribes. SolidCable replays only
    # from the subscription time, so they are never delivered. Instead we
    # broadcast once below — by then the LLM has responded (seconds later) and
    # the subscription is reliably established.
    Message.suppressing_turbo_broadcasts do
      chat.complete
    end

    Turbo::StreamsChannel.broadcast_remove_to(
      "chat_#{chat_id}",
      target: "thinking-indicator"
    )

    assistant = chat.messages.where(role: "assistant").order(:id).last
    if assistant
      Turbo::StreamsChannel.broadcast_append_to(
        "chat_#{chat_id}",
        target: "messages",
        partial: "messages/assistant",
        locals: { message: assistant }
      )
    end
  rescue RubyLLM::RateLimitError
    broadcast_error(chat_id, "rate limit reached",
      "The AI provider has hit its daily request limit. Please try again later.")
  rescue RubyLLM::ConfigurationError
    # Not a RubyLLM::Error subclass, so it needs its own rescue. Fires if a
    # chat's model has no credentials configured for its provider — normally
    # prevented by the RepointNonAnthropicChatsToDefaultModel migration and
    # the CHAT_MODELS allowlist, but kept as a safety net so a chat left in
    # this state degrades to a visible error instead of silently never
    # replying (see issue #45 — this was the failure mode `RubyLLM::Error`
    # alone didn't catch).
    broadcast_error(chat_id, "ai error",
      "This chat's model is no longer available. Start a new chat to keep going.")
  rescue RubyLLM::ModelNotFoundError
    # Also not a RubyLLM::Error subclass (same gap as ConfigurationError above).
    # Fires when a chat's model_id isn't in this environment's `models` table
    # yet — e.g. a newly-added model whose row hasn't been pulled in by
    # Model.refresh! since the last deploy (see issue #49). Without this the
    # job dies unhandled: the thinking-indicator is never removed and no
    # error reaches the user, so the chat just looks stuck forever.
    broadcast_error(chat_id, "ai error",
      "This chat's model isn't available right now. Start a new chat to keep going.")
  rescue RubyLLM::Error => e
    broadcast_error(chat_id, "ai error", e.message)
  rescue Faraday::TimeoutError
    broadcast_error(chat_id, "request timed out",
      "The AI provider did not respond in time. Please try again.")
  ensure
    # Always refresh generation-action so any loading state is cleared,
    # whether the job succeeded or failed.
    chat = Chat.find_by(id: chat_id)
    return unless chat

    Turbo::StreamsChannel.broadcast_replace_to(
      "chat_#{chat_id}",
      target: "generation-action",
      partial: "chats/generation_action",
      locals: { chat: chat }
    )
  end

  private

  # Lightweight stand-in for the _error partial, which only needs id and created_at.
  ErrorStub = Struct.new(:id, :created_at)

  def broadcast_error(chat_id, title, body)
    stub = ErrorStub.new("error_#{chat_id}", Time.current)
    Turbo::StreamsChannel.broadcast_append_to(
      "chat_#{chat_id}",
      target: "messages",
      partial: "messages/error",
      locals: { message: stub, title: title, error_message: body }
    )
  end
end
