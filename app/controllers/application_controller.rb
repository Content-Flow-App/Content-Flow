class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :check_creator_exist

  # The models actually configured and working (see
  # config/initializers/ruby_llm.rb): Claude Opus 5, Sonnet 5 (default), and
  # Haiku 4.5 direct on `anthropic`; DeepSeek's V4 Flash and Pro direct on
  # `deepseek`; and Kimi K3 / GLM-5.2 fronted by `openrouter` (issue #47 —
  # open-weight models reinstated through real, dedicated credentials this
  # time, not the shared GitHub Models aggregator dropped in issue #45). Each
  # entry was verified live against its own provider's model-listing API
  # before being added here (see openspec/changes/add-open-source-models).
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
    %w[anthropic claude-haiku-4-5-20251001],
    %w[deepseek deepseek-v4-flash],
    %w[deepseek deepseek-v4-pro],
    %w[openrouter moonshotai/kimi-k3],
    %w[openrouter z-ai/glm-5.2]
  ].freeze

  # OpenRouter fronts multiple publishers under RubyLLM's single `openrouter`
  # provider tag, so `model.provider_class&.name` would mislabel these rows
  # "Openrouter - Kimi K3" instead of naming the real publisher. Each
  # OpenRouter-routed row carries its true publisher in
  # metadata[:real_publisher] (see Model.tag_real_publishers! — reapplied
  # after every Model.refresh!, since refresh! overwrites metadata wholesale
  # from OpenRouter's live catalog); this reads it back for display instead
  # of trusting the registry's provider field. DeepSeek-native and Anthropic
  # rows carry no such tag and fall through to the normal path unchanged.
  REAL_PUBLISHER_NAMES = {
    "moonshotai" => "Moonshot AI",
    "zhipu" => "Zhipu"
  }.freeze

  def chat_model_provider_label(model)
    real_publisher = model.metadata[:real_publisher] || model.metadata["real_publisher"]
    return model.provider_class&.name || model.provider unless real_publisher

    REAL_PUBLISHER_NAMES.fetch(real_publisher, real_publisher)
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
