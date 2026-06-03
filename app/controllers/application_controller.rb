class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :check_creator_exist, unless: :devise_controller?

  private

  def available_chat_models
    RubyLLM.models.chat_models.all
           .sort_by { |model| [ model.provider.to_s, model.name.to_s ] }
  end

  def check_creator_exist
    redirect_to new_creator_path if current_user && current_user.creator.blank?
  end
end
