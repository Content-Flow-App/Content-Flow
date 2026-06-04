class ChatsController < ApplicationController
  before_action :set_chat, only: [ :show, :destroy ]

  def index
    @chats = Chat.order(created_at: :desc)
  end

  def new
    @chat = Chat.new
    @selected_model = params[:model]
    @chat_models = available_chat_models
  end

  def create
    prompt = params.dig(:chat, :prompt)
    if prompt.present?
      @chat = Chat.create!(
        model: params.dig(:chat, :model).presence,
        chattable: chattable
      )

      # Persist the creator-aware system prompt as a role: :system message
      # before the job runs. ChatResponseJob's chat.ask then streams with the
      # context already in place. A standalone chat (no chattable) yields nil
      # instructions, leaving the plain /chats flow untouched.
      instructions = LlmContext.for(@chat.chattable)
      @chat.with_instructions(instructions) if instructions.present?

      ChatResponseJob.perform_later(@chat.id, prompt)

      redirect_to @chat, notice: "Chat was successfully created."
    end
  end

  def show
    @message = @chat.messages.build
  end

  def destroy
    @chat.destroy!
    redirect_to chats_path, notice: "Chat was successfully destroyed.", status: :see_other
  end

  private

  def set_chat
    @chat = Chat.find(params[:id])
  end

  # Resolves an optional chat owner from the submitted params. F2 wires the
  # idea/script/post chat entry points to submit chattable_type/chattable_id;
  # until then (and for the standalone /chats form) these are absent and we
  # return nil — an ownerless chat, which is valid (optional: true).
  #
  # The type is allowlisted before constantize so a request can never coerce
  # an arbitrary class name into a model load.
  CHATTABLE_TYPES = %w[User Idea Script LinkedinPost].freeze

  def chattable
    type = params.dig(:chat, :chattable_type).presence
    id   = params.dig(:chat, :chattable_id).presence
    return unless type && id && CHATTABLE_TYPES.include?(type)

    type.constantize.find(id)
  end
end
