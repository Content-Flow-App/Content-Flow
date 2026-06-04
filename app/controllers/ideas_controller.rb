class IdeasController < ApplicationController
  before_action :authenticate_user!
  before_action :set_idea, only: [:show, :edit, :update, :destroy]

  def index
    @ideas = current_user.ideas.order(created_at: :desc)
  end

  def show
  end

  def new
    @idea = current_user.ideas.build(
      title: params[:title],
      description: params[:description],
      topic: params[:topic]
    )
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
      redirect_to idea_path(@idea), notice: "Idea updated."
    else
      render :edit, status: :unprocessable_entity
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
