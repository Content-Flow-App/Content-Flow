class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  private

  def available_chat_models
    RubyLLM.models.chat_models.all
           .sort_by { |model| [ model.provider.to_s, model.name.to_s ] }
  end
end
