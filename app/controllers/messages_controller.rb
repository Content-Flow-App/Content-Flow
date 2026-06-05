class MessagesController < ApplicationController
  before_action :set_chat

  def create
    content = params.dig(:message, :content)
    if content.present?
      # Persist the user message here (not inside the job) so it appears
      # immediately — its create broadcast appends to the already-subscribed
      # page, and the job only streams the assistant reply. Mirrors
      # ChatsController#create.
      @chat.create_user_message(content)
      ChatResponseJob.perform_later(@chat.id)

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @chat }
      end
    end
  end

  private

  def set_chat
    @chat = Chat.find(params[:chat_id])
  end
end
