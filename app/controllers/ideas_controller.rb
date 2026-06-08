class IdeasController < ApplicationController
  before_action :authenticate_user!
  before_action :set_idea, only: [:show, :edit, :update, :destroy]

  def index
    @ideas = current_user.ideas.order(created_at: :desc)
  end

  def show
  end

  # Conventionally `new` renders `ideas/new.html.erb` (implicit template lookup)
  # to show a blank form. In the chat-driven generation flow we repurpose it as a
  # `redirect_to`: an idea is born from a conversation, so `new` hands off to the
  # chat composer carrying the purpose + owner. No template is rendered here.
  # (`create` and `new.html.erb` stay — `create` re-renders `new` on a validation
  # error, e.g. when the generation engine's payload fails validation.)
  def new
    redirect_to new_chat_path(purpose: "generate_idea",
                              chattable_type: "User", chattable_id: current_user.id)
  end

  def create
    @idea = current_user.ideas.build(idea_params)
    if @idea.save
      redirect_to idea_path(@idea), notice: "Idea saved."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @idea.update(idea_params)
      respond_to do |format|
        format.html { redirect_to idea_path(@idea) }
        format.json { head :ok }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @idea.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @idea.destroy
    redirect_to ideas_path, notice: "Idea deleted."
  end

  private

  def set_idea
    @idea = current_user.ideas.find(params[:id])
  end

  def idea_params
    params.require(:idea).permit(:title, :description, :topic)
  end
end
