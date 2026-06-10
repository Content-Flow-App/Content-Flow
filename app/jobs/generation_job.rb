# GenerationJob runs the slow half of "save as ..." in the background: the
# one-shot structured LLM extraction and the save. GenerationsController does
# the fast half in the request (authorize the owner, guard the transcript),
# enqueues this job, and responds immediately with a loading state; this job
# then broadcasts the outcome over the chat's Turbo Stream — a redirect to the
# new record on success, an error message plus the restored button on failure.
#
# Active Job notes:
#   - `perform_later(chat.id, user.id)` serializes the arguments and hands them
#     to the queue adapter (:async in development, Solid Queue in production).
#     `perform` runs later, possibly in another process, so everything is
#     re-fetched from the database — no controller or request state survives.
#   - We could pass the records themselves (Active Job would serialize them as
#     GlobalIDs and re-find them on perform); we pass plain ids to match
#     ChatResponseJob and keep the find/rescue explicit.
class GenerationJob < ApplicationJob
  # The GenerationPlan procs are written against a controller: they call
  # `current_user`, the user-scoped relations from UserScopedResource, and path
  # helpers like `idea_path`. Including the same concern + the route helpers
  # (and defining `current_user` below) gives this job the same vocabulary, so
  # the procs run here unchanged via instance_exec.
  include UserScopedResource
  include Rails.application.routes.url_helpers

  def perform(chat_id, user_id)
    @chat = Chat.find(chat_id)
    @current_user = User.find(user_id)

    plan = GenerationPlan.for(@chat)

    # Re-resolve the owner through the user-scoped relation, exactly like the
    # controller did at enqueue time. The controller's check is the real
    # authorization gate; repeating it here also covers a record deleted
    # between enqueue and run (raises RecordNotFound -> rescued below).
    owner = instance_exec(@chat.chattable_id, &plan.owner_resolver)

    attributes = extract_attributes(plan, owner)
    persist_and_broadcast(plan, owner, attributes)
  rescue ActiveRecord::RecordNotFound
    broadcast_failure("Couldn't save — this chat's owner no longer exists.") if @chat
  rescue StructuredExtraction::ExtractionFailed, RubyLLM::Error
    broadcast_failure("Generation failed — please try again.")
  rescue Faraday::TimeoutError
    broadcast_failure("The AI provider did not respond in time. Please try again.")
  end

  private

  # The GenerationPlan procs call `current_user`; in a job that's the user who
  # clicked save, passed in by the controller at enqueue time.
  attr_reader :current_user

  # Extract structured content on a TRANSIENT chat (StructuredExtraction builds
  # its own RubyLLM.chat) so the visible transcript on @chat stays clean. The
  # returned Hash is sliced to the schema's declared keys — the schema is the
  # allow-list, so the model can't set an attribute it didn't declare.
  def extract_attributes(plan, owner)
    payload = StructuredExtraction.extract(
      schema: plan.schema,
      prompt: @chat.transcript,
      instructions: LlmContext.for(owner),
      model: @chat.model_id.presence || RubyLLM.config.default_model
    )
    StructuredContent.attributes_for(plan.schema, payload)
  end

  # Build (or, for the singular posts, update) the record off the owner and
  # save with a non-bang save: a validation failure becomes a broadcast error,
  # not a dead job.
  def persist_and_broadcast(plan, owner, attributes)
    record = instance_exec(owner, attributes, &plan.persist)

    if record.save
      broadcast_redirect(instance_exec(record, &plan.redirect_target))
    else
      broadcast_failure("Couldn't save: #{record.errors.full_messages.to_sentence}")
    end
  end

  # Swap the loading state for a partial that carries a Stimulus `redirect`
  # controller: when it lands in the DOM it Turbo.visits the record's show
  # page, with a visible "view your ..." link as the fallback.
  def broadcast_redirect(url)
    Turbo::StreamsChannel.broadcast_replace_to(
      "chat_#{@chat.id}",
      target: "generation-action",
      partial: "chats/generation_redirect",
      locals: { chat: @chat, url: url }
    )
  end

  # Lightweight stand-in for the _error partial, which only needs id and created_at.
  ErrorStub = Struct.new(:id, :created_at)

  # Append the error to the message list and put the save button back so the
  # user can retry — never leave a permanent spinner.
  def broadcast_failure(body)
    stub = ErrorStub.new("generation_error_#{@chat.id}", Time.current)
    Turbo::StreamsChannel.broadcast_append_to(
      "chat_#{@chat.id}",
      target: "messages",
      partial: "messages/error",
      locals: { message: stub, title: "save failed", error_message: body }
    )

    Turbo::StreamsChannel.broadcast_replace_to(
      "chat_#{@chat.id}",
      target: "generation-action",
      partial: "chats/generation_action",
      locals: { chat: @chat }
    )
  end
end
