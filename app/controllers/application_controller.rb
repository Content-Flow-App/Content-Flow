class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :check_creator_exist

  # The only providers actually configured with working credentials (see
  # config/initializers/ruby_llm.rb). RubyLLM's registry knows about ~1350
  # models across a dozen more providers (gemini, deepseek, mistral,
  # perplexity, xai, azure, bedrock, vertexai, openrouter, ollama, gpustack)
  # that would raise RubyLLM::ConfigurationError if picked — this allowlist
  # keeps `available_chat_models` safe regardless of what happens to be in
  # the `models` table.
  CHAT_PROVIDERS = %w[openai anthropic].freeze

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
           .select { |model| CHAT_PROVIDERS.include?(model.provider.to_s) }
           .sort_by { |model| [ model.provider.to_s, model.name.to_s ] }
  end
end
