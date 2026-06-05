# GenerationsController turns a finished chat conversation into a saved record.
# One generic synchronous flow handles every generate purpose; the per-purpose
# differences (schema, owner, persistence, redirect) come from GenerationPlan.
#
# Flow: authorize the owner -> build a transcript -> extract structured content
# on a throwaway chat -> assign through the schema allow-list -> save -> redirect
# to the new record. Anything that can fail an LLM call is caught so a slow or
# misbehaving endpoint sends the user back to the chat with a flash, not a 500.
class GenerationsController < ApplicationController
  include UserScopedResource

  before_action :authenticate_user!
  before_action :set_chat

  def create
    plan  = GenerationPlan.for(@chat)

    # Re-resolve & AUTHORIZE the owner through a user-scoped relation. We read
    # only the chat's stored chattable_id (a bare FK) and never trust the loaded
    # chat.chattable object: the scoped `.find` IS the authorization, raising
    # ActiveRecord::RecordNotFound — a 404 — for a chat the user doesn't own.
    owner = instance_exec(@chat.chattable_id, &plan.owner_resolver)

    transcript = chat_transcript
    return redirect_to(@chat, alert: "Add a message to the chat before generating.") if transcript.blank?

    attributes = extract_attributes(plan, owner, transcript)
    persist_and_redirect(plan, owner, attributes)
  rescue GenerationPlan::UnknownPurpose
    redirect_to @chat, alert: "This chat isn't set up to generate anything."
  rescue StructuredExtraction::ExtractionFailed, RubyLLM::Error
    redirect_to @chat, alert: "Generation failed — please try again."
  end

  private

  def set_chat
    @chat = Chat.find(params[:chat_id])
  end

  # persist builds a new record off the owner (or, for a singular linkedin_post,
  # updates the existing one) with the extracted attrs assigned, then saves with
  # a non-bang save so a validation failure returns to the chat rather than 500s.
  def persist_and_redirect(plan, owner, attributes)
    record = instance_exec(owner, attributes, &plan.persist)

    if record.save
      redirect_to instance_exec(record, &plan.redirect_target), notice: "Saved from your chat."
    else
      redirect_to @chat, alert: "Couldn't save: #{record.errors.full_messages.to_sentence}"
    end
  end

  # Extract structured content on a TRANSIENT chat (StructuredExtraction builds
  # its own RubyLLM.chat) so the visible transcript on @chat stays clean.
  # with_schema is the primary path; StructuredExtraction falls back to
  # prompt-JSON if the endpoint ignores response_format (F-3). The returned Hash
  # is sliced to the schema's declared keys (== plan.permitted_keys) — the schema
  # is the allow-list, so the model can't set an attribute it didn't declare.
  def extract_attributes(plan, owner, transcript)
    payload = StructuredExtraction.extract(
      schema: plan.schema,
      prompt: transcript,
      instructions: LlmContext.for(owner),
      model: @chat.model_id.presence || RubyLLM.config.default_model
    )
    StructuredContent.attributes_for(plan.schema, payload)
  end

  # The visible conversation as a plain transcript for the extraction ask. Only
  # real user/assistant turns — the persisted system instruction (LlmContext)
  # and any blank or tool messages are excluded.
  def chat_transcript
    @chat.messages
         .where(role: %w[user assistant])
         .where.not(content: [nil, ""])
         .order(:created_at)
         .map { |message| "#{message.role}: #{message.content}" }
         .join("\n\n")
  end
end
