class ChatsController < ApplicationController
  before_action :set_chat, only: [ :show, :destroy ]

  def index
    @chats = Chat.order(created_at: :desc)
  end

  def new
    @purpose = purpose
    @chat = Chat.new(purpose: @purpose, chattable: default_chattable)
    @selected_model = params[:model]
    @chat_models = available_chat_models
    @seed_prompt = substack_seed_prompt
  end

  def create
    prompt = params.dig(:chat, :prompt)
    if prompt.present?
      @chat = Chat.create!(
        model: params.dig(:chat, :model).presence,
        chattable: chattable,
        purpose: purpose
      )

      # Persist the creator-aware system prompt as a role: :system message
      # before the job runs, so the assistant streams with the context already in
      # place. A standalone chat (no chattable) yields nil instructions, leaving
      # the plain /chats flow untouched.
      instructions = LlmContext.for(@chat.chattable)
      @chat.with_instructions(instructions) if instructions.present?

      # Persist the user's message synchronously, before enqueuing the job, so the
      # chat page renders it on load. The job then only streams the assistant
      # reply — avoiding the race where the job's broadcast fires before the
      # browser has subscribed to the chat's Turbo Stream.
      @chat.create_user_message(prompt)
      ChatResponseJob.perform_later(@chat.id)

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

  # Resolves an optional chat owner from the params. It arrives two ways, like
  # `purpose`: as top-level query params on the generate redirect from a content
  # `new` action (/chats/new?chattable_type=Idea&chattable_id=7), and as the
  # form's hidden chat[chattable_type]/chat[chattable_id] fields on #create. One
  # helper reads both; absent (the standalone /chats form) → nil, an ownerless
  # chat, which is valid (optional: true).
  #
  # The type is allowlisted before constantize so a request can never coerce
  # an arbitrary class name into a model load.
  CHATTABLE_TYPES = %w[User Idea Script LinkedinPost].freeze

  def chattable
    type = (params[:chattable_type] || params.dig(:chat, :chattable_type)).presence
    id   = (params[:chattable_id]   || params.dig(:chat, :chattable_id)).presence
    return unless type && id && CHATTABLE_TYPES.include?(type)

    type.constantize.find(id)
  end

  # The MVP generation purposes. Allow-listed exactly like CHATTABLE_TYPES so an
  # arbitrary string from the query/form never reaches the enum (which would
  # otherwise fail validation). Anything off the list collapses to nil — a plain
  # free-form chat, behavior unchanged.
  PURPOSES = %w[generate_idea generate_script generate_linkedin_post].freeze

  # Read the requested purpose from either source: it arrives as a top-level
  # query param on the #new redirect (/chats/new?purpose=generate_idea) and as
  # the form's hidden chat[purpose] field on #create. One helper serves both.
  def purpose
    requested = params[:purpose].presence || params.dig(:chat, :purpose).presence
    requested if PURPOSES.include?(requested)
  end

  # For #new only: seed the form's owner. Top-level chats hang off the User (see
  # USER_JOURNEYS decision 4), so a generate_idea chat with no explicit owner
  # defaults to the current user; any explicitly-passed chattable wins.
  def default_chattable
    chattable || (current_user if purpose == "generate_idea")
  end

  # Builds a pre-filled prompt from a Substack post so the user can see and
  # edit the seed text before sending. Always scoped through current_user so
  # a user can only seed from their own cached posts.
  def substack_seed_prompt
    return unless params[:substack_post_id].present?

    post = current_user.substack_posts.find_by(id: params[:substack_post_id])
    return unless post

    source_label = post.substack_source.name.presence ||
                   post.substack_source.handle&.concat(".substack.com")

    lines = [ "I want to create content inspired by this Substack post:" ]
    lines << "Title: \"#{post.title}\""         if post.title.present?
    lines << "Author: #{post.author}"            if post.author.present?
    lines << "Source: #{source_label}"           if source_label.present?
    lines << ""
    lines << post.summary                        if post.summary.present?
    lines << ""
    lines << "Help me develop this into a content idea for my brand."
    lines.join("\n")
  end
end
