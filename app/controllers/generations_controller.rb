# GenerationsController turns a finished chat conversation into a saved record.
# The request thread does only the fast, user-facing parts — authorize the
# owner and guard the transcript — then hands the slow LLM extraction to
# GenerationJob and responds immediately with a loading state. The job
# broadcasts the redirect (or an error) back over the chat's Turbo Stream, so
# the user sees: click -> "saving your idea..." -> lands on the new record.
class GenerationsController < ApplicationController
  include UserScopedResource

  before_action :authenticate_user!
  before_action :set_chat

  def create
    plan = GenerationPlan.for(@chat)

    # A nil chattable_id means the chat was started without a proper owner
    # (e.g. navigating directly to /chats/new?purpose=generate_script without
    # the chattable params). Redirect early rather than letting owner_resolver
    # call find(nil), which would raise RecordNotFound and 404 — masking the
    # real cause. A non-nil id that doesn't belong to the current user still
    # 404s intentionally via the scoped find below (authorization check).
    if @chat.chattable_id.nil?
      return redirect_to @chat, alert: "This chat isn't linked to an owner — start it from the correct page."
    end

    # Re-resolve & AUTHORIZE the owner through a user-scoped relation. We read
    # only the chat's stored chattable_id (a bare FK) and never trust the loaded
    # chat.chattable object: the scoped `.find` IS the authorization, raising
    # ActiveRecord::RecordNotFound — a 404 — for a chat the user doesn't own.
    # This must happen HERE, in the request, so a non-owner gets the 404; a
    # background job can't send an HTTP status back.
    instance_exec(@chat.chattable_id, &plan.owner_resolver)

    return redirect_to(@chat, alert: "Add a message to the chat before generating.") if @chat.transcript.blank?

    GenerationJob.perform_later(@chat.id, current_user.id)

    # button_to submits through Turbo, which sends
    # `Accept: text/vnd.turbo-stream.html, text/html`, so respond_to picks the
    # turbo_stream branch. With no explicit render, implicit template lookup
    # finds app/views/generations/create.turbo_stream.erb (controller name /
    # action name . format) — that template swaps the button for the loading
    # state. The html branch covers non-Turbo submits with a plain redirect.
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to @chat, notice: "Saving from your chat..." }
    end
  rescue GenerationPlan::UnknownPurpose
    redirect_to @chat, alert: "This chat isn't set up to generate anything."
  end

  private

  def set_chat
    @chat = Chat.find(params[:chat_id])
  end
end
