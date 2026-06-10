class TwitterPostsController < ApplicationController
  include UserScopedResource

  before_action :authenticate_user!
  before_action :set_parent
  before_action :set_twitter_post, only: [ :show, :edit, :update, :destroy ]

  def show
  end

  def new
    chattable = @script || @idea
    redirect_to new_chat_path(purpose: "generate_twitter_post",
                              chattable_type: chattable.class.name,
                              chattable_id: chattable.id)
  end

  def create
    @twitter_post = (@script || @idea).build_twitter_post(twitter_post_params)
    if @twitter_post.save
      redirect_to post_show_path, notice: "Twitter post saved."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @twitter_post.update(twitter_post_params)
      redirect_to post_show_path, notice: "Twitter post updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @twitter_post.destroy
    redirect_to (@script ? script_path(@script) : idea_path(@idea)), notice: "Twitter post deleted."
  end

  private

  def set_parent
    if params[:script_id]
      @script = current_user_scripts.find(params[:script_id])
    elsif params[:idea_id]
      @idea = current_user.ideas.find(params[:idea_id])
    end
  end

  def set_twitter_post
    @twitter_post = @script ? @script.twitter_post : @idea.twitter_post
  end

  def post_show_path
    @script ? script_twitter_post_path(@script) : idea_twitter_post_path(@idea)
  end

  def twitter_post_params
    params.require(:twitter_post).permit(:title, :hook, :body)
  end
end
