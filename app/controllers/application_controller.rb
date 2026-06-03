class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  private

  def after_sign_up_path_for(_resource)
    onboarding_welcome_path
  end

  def after_sign_out_path_for(_resource_or_scope)
    new_user_session_path
  end

  def available_chat_models
    RubyLLM.models.chat_models.all
           .sort_by { |model| [ model.provider.to_s, model.name.to_s ] }
  end
end
