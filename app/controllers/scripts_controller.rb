class ScriptsController < ApplicationController
  include UserScopedResource

  before_action :authenticate_user!
  before_action :set_idea, only: [:index, :new, :create]
  before_action :set_script, only: [:show, :edit, :update, :destroy]

  def index
    @scripts = @idea.scripts
  end

  def show
  end

  # Repurposed as a redirect (see IdeasController#new). @idea is loaded by the
  # set_idea before_action, so the generation chat is owned by — and gets its
  # context from — the parent idea.
  def new
    redirect_to new_chat_path(purpose: "generate_script",
                              chattable_type: "Idea", chattable_id: @idea.id)
  end

  def create
    @script = @idea.scripts.build(script_params)
    if @script.save
      redirect_to script_path(@script), notice: "Script saved."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @script.update(script_params)
      redirect_to script_path(@script), notice: "Script updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @script.destroy
    redirect_to idea_path(@idea), notice: "Script deleted."
  end

  private

  def set_idea
    @idea = current_user.ideas.find(params[:idea_id])
  end

  def set_script
    @script = current_user_scripts.find(params[:id])
    @idea = @script.idea
  end

  def script_params
    params.require(:script).permit(:title, :description, :length, :style, :system_prompt)
  end
end
