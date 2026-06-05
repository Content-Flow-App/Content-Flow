class LinkedinPostsController < ApplicationController
  include UserScopedResource

  before_action :authenticate_user!
  before_action :set_script
  before_action :set_linkedin_post, only: [ :show, :edit, :update, :destroy ]

  def show
  end

  # Repurposed as a redirect (see IdeasController#new). @script is loaded by the
  # set_script before_action. The old "post already exists? → edit" guard is gone:
  # in the generation flow the create-vs-update decision moves to the generation
  # engine (F-2), which updates an existing post or builds a new one.
  def new
    redirect_to new_chat_path(purpose: "generate_linkedin_post",
                              chattable_type: "Script", chattable_id: @script.id)
  end

  def create
    @linkedin_post = @script.build_linkedin_post(linkedin_post_params)
    if @linkedin_post.save
      redirect_to script_linkedin_post_path(@script), notice: "LinkedIn post saved."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @linkedin_post.update(linkedin_post_params)
      redirect_to script_linkedin_post_path(@script), notice: "LinkedIn post updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @linkedin_post.destroy
    redirect_to script_path(@script), notice: "LinkedIn post deleted."
  end

  private

  def set_script
    @script = current_user_scripts.find(params[:script_id])
  end

  # singular resource — no :id in the path, so we load via the association.
  # Equivalent: LinkedinPost.find_by!(script_id: @script.id)
  def set_linkedin_post
    @linkedin_post = @script.linkedin_post
  end

  def linkedin_post_params
    params.require(:linkedin_post).permit(:title, :hook, :body)
  end
end
