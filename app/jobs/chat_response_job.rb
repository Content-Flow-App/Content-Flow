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

    chat.complete do |chunk|
      if chunk.content && !chunk.content.empty?
        message = chat.messages.last
        message.broadcast_append_chunk(chunk.content)
      end
    end
  end
end
