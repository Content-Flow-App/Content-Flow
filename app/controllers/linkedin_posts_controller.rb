class LinkedinPostsController < ApplicationController
  include UserScopedResource

  before_action :authenticate_user!
  before_action :set_parent
  before_action :set_linkedin_post, only: [ :show, :edit, :update, :destroy ]

  def show
  end

  # Redirects to the chat composer with the appropriate chattable context.
  # For the scripted path the chattable is the Script (existing behaviour);
  # for the direct path it is the Idea.
  def new
    chattable = @script || @idea
    redirect_to new_chat_path(purpose: "generate_linkedin_post",
                              chattable_type: chattable.class.name,
                              chattable_id: chattable.id)
  end

  def create
    @linkedin_post = (@script || @idea).build_linkedin_post(linkedin_post_params)
    if @linkedin_post.save
      redirect_to post_show_path, notice: "LinkedIn post saved."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @linkedin_post.update(linkedin_post_params)
      redirect_to post_show_path, notice: "LinkedIn post updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @linkedin_post.destroy
    redirect_to (@script ? script_path(@script) : idea_path(@idea)), notice: "LinkedIn post deleted."
  end

  private

  # Resolves the parent from whichever FK is present in the URL.
  # Script path:  /scripts/:script_id/linkedin_post  → @script (user-scoped via concern)
  # Direct path:  /ideas/:idea_id/linkedin_post       → @idea   (user-scoped via current_user)
  def set_parent
    if params[:script_id]
      @script = current_user_scripts.find(params[:script_id])
    elsif params[:idea_id]
      @idea = current_user.ideas.find(params[:idea_id])
    end
  end

  # Singular resource — no :id in the URL. Load via the parent association.
  def set_linkedin_post
    @linkedin_post = @script ? @script.linkedin_post : @idea.linkedin_post
  end

  def post_show_path
    @script ? script_linkedin_post_path(@script) : idea_linkedin_post_path(@idea)
  end

  def linkedin_post_params
    params.require(:linkedin_post).permit(:title, :hook, :body)
  end
end
