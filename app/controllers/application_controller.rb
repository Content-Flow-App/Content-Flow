class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :check_creator_exist

  # The only models actually configured and working (see
  # config/initializers/ruby_llm.rb): Claude Opus 5, Sonnet 5 (default), and
  # Haiku 4.5, all direct on the `anthropic` provider. GitHub Models — the
  # prior route to OpenAI/Mistral/DeepSeek chat models — was dropped entirely
  # (issue #45): GitHub confirmed via live API error it's mid "scheduled
  # retirement brownout", i.e. sunsetting the endpoint, not a transient
  # outage. Any chat routed through it was liable to break in production with
  # no recovery, so Anthropic direct is now the only supported provider.
  #
  # Still paired as exact [provider, model_id] rather than a bare provider
  # allowlist: RubyLLM.models.chat_models tags plenty of non-chat models as
  # `type: "chat"` regardless of provider — dall-e-3, whisper-1, tts-1,
  # sora-2, and other image/audio/video models the registry doesn't
  # distinguish from real chat models. Pairing the exact id avoids matching
  # those.
  CHAT_MODELS = [
    %w[anthropic claude-opus-5],
    %w[anthropic claude-sonnet-5],
    %w[anthropic claude-haiku-4-5-20251001]
  ].freeze

  def chat_model_provider_label(model)
    model.provider_class&.name || model.provider
  end
  helper_method :chat_model_provider_label

  def chat_model_label(model)
    "#{chat_model_provider_label(model)} - #{model.name}"
  end
  helper_method :chat_model_label

  private

  def after_sign_up_path_for(resource)
    onboarding_path_for(resource)
  end

  def after_sign_in_path_for(resource)
    onboarding_path_for(resource)
  end

  def check_creator_exist
    return unless user_signed_in?
    return if devise_controller?
    redirect_to creator_path unless current_user.creator.present?
  end

  def onboarding_path_for(user)
    case user.next_onboarding_step
    when :creator then creator_path
    when :idea    then new_idea_path
    when :script  then new_idea_script_path(user.ideas.first)
    when :post    then new_script_linkedin_post_path(Script.where(idea: user.ideas).first)
    else               dashboard_path
    end
  end

  def available_chat_models
    RubyLLM.models.chat_models.all
           .select { |model| CHAT_MODELS.include?([ model.provider.to_s, model.id ]) }
           .sort_by { |model| [ model.provider.to_s, model.name.to_s ] }
  end
end
