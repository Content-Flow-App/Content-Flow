class InstagramPostsController < ApplicationController
  include UserScopedResource

  before_action :authenticate_user!
  before_action :set_parent
  before_action :set_instagram_post, only: [ :show, :edit, :update, :destroy ]

  def show
  end

  def new
    chattable = @script || @idea
    redirect_to new_chat_path(purpose: "generate_instagram_post",
                              chattable_type: chattable.class.name,
                              chattable_id: chattable.id)
  end

  def create
    @instagram_post = (@script || @idea).build_instagram_post(instagram_post_params)
    if @instagram_post.save
      redirect_to post_show_path, notice: "Instagram post saved."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @instagram_post.update(instagram_post_params)
      redirect_to post_show_path, notice: "Instagram post updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @instagram_post.destroy
    redirect_to (@script ? script_path(@script) : idea_path(@idea)), notice: "Instagram post deleted."
  end

  private

  def set_parent
    if params[:script_id]
      @script = current_user_scripts.find(params[:script_id])
    elsif params[:idea_id]
      @idea = current_user.ideas.find(params[:idea_id])
    end
  end

  def set_instagram_post
    @instagram_post = @script ? @script.instagram_post : @idea.instagram_post
  end

  def post_show_path
    @script ? script_instagram_post_path(@script) : idea_instagram_post_path(@idea)
  end

  def instagram_post_params
    params.require(:instagram_post).permit(:title, :hook, :body)
  end
end
