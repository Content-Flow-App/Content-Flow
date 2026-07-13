class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :check_creator_exist

  # The only models actually configured and working (see
  # config/initializers/ruby_llm.rb): Claude Sonnet 5 (default, anthropic),
  # plus GitHub Models — a multi-vendor aggregator, not just OpenAI, all
  # reachable through GITHUB_TOKEN. Every entry below was verified live
  # against models.github.ai before being added. An earlier pass scoped this
  # by provider instead (openai/anthropic), but that let two kinds of false
  # positives through:
  #
  #   - RubyLLM.models.chat_models tags plenty of non-chat models as
  #     `type: "chat"` regardless of provider — dall-e-3, whisper-1, tts-1,
  #     sora-2, and other image/audio/video models the registry doesn't
  #     distinguish from real chat models.
  #   - `gpt-4o` / `gpt-4o-mini` also exist under the `azure` provider with
  #     the identical bare id — a provider allowlist alone can't tell those
  #     apart from the `openai` rows that are actually reachable, and azure
  #     isn't configured at all in this app.
  #
  # Pairing exact [provider, model_id] avoids both: it can't match a non-chat
  # model (wrong id) or an unconfigured provider's same-named model (wrong
  # provider).
  #
  # The `mistral-ai/...` and `deepseek/...` rows are real Mistral/DeepSeek
  # models, but GitHub Models is the only credential we have for them — there
  # is no separate mistral_api_key/deepseek_api_key configured, so these are
  # deliberately registered under the `openai` provider (our one GitHub
  # Models credential slot) with the full "publisher/model" id GitHub Models
  # expects verbatim. See GithubModelsModelPrefix below: it only prefixes
  # bare ids, so an id that already contains "/" (like these) passes through
  # unprefixed. Not everything GitHub Models lists actually works with this
  # token — gpt-5-* and the o1/o3/o4 reasoning tiers returned 400/403 when
  # tested and are deliberately not included.
  CHAT_MODELS = [
    %w[anthropic claude-sonnet-5],
    %w[openai gpt-4o],
    %w[openai gpt-4o-mini],
    %w[openai gpt-4.1],
    %w[openai mistral-ai/mistral-small-2503],
    %w[openai deepseek/deepseek-v3-0324]
  ].freeze

  # RubyLLM::Model::Info#label always reads "<provider_class.name> - <name>"
  # — correct for real OpenAI models, but would mislabel the mistral-ai/ and
  # deepseek/ rows above as "OpenAI - ..." since they're registered under the
  # openai provider for credential-routing reasons only (see CHAT_MODELS
  # comment). Those rows carry the true publisher in metadata[:real_publisher]
  # at creation time; this reads it back for display instead of trusting the
  # registry's provider field.
  REAL_PUBLISHER_NAMES = {
    "mistral-ai" => "Mistral",
    "deepseek" => "DeepSeek"
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
