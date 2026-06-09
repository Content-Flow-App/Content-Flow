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

    Turbo::StreamsChannel.broadcast_replace_to(
      "chat_#{chat_id}",
      target: "generation-action",
      partial: "chats/generation_action",
      locals: { chat: chat }
    )
  end
end
