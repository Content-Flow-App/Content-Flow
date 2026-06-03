class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  before_action :check_creator_exist

  private

  def after_sign_up_path_for(resource)
    onboarding_path_for(resource)
  end

  def after_sign_in_path_for(resource)
    onboarding_path_for(resource)
  end

  def check_creator_exist
    return unless user_signed_in?
    redirect_to new_creator_path unless current_user.creator.present?
  end

  def onboarding_path_for(user)
    case user.next_onboarding_step
    when :creator then new_creator_path
    when :idea    then new_idea_path
    when :script  then new_idea_script_path(user.ideas.first)
    when :post    then new_script_linkedin_post_path(Script.where(idea: user.ideas).first)
    else               dashboard_path
    end
  end

  def available_chat_models
    RubyLLM.models.chat_models.all
           .sort_by { |model| [ model.provider.to_s, model.name.to_s ] }
  end
end
