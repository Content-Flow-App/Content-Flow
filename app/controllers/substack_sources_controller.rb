# SubstackSourcesController manages CRUD-lite for a user's Substack subscriptions.
#
# `resources :substack_sources, only: [:index, :new, :create, :destroy]` generates:
#   GET    /substack_sources          → #index   (substack_sources_path)
#   GET    /substack_sources/new      → #new     (new_substack_source_path)
#   POST   /substack_sources          → #create  (substack_sources_path)
#   DELETE /substack_sources/:id      → #destroy (substack_source_path(id))
#
# All queries go through `current_user.substack_sources` so a user can never
# act on another user's sources.
class SubstackSourcesController < ApplicationController
  before_action :set_source, only: [:destroy]

  def index
    @sources = current_user.substack_sources.order(created_at: :desc)
  end

  def new
    @source = current_user.substack_sources.build
  end

  def create
    @source = current_user.substack_sources.build(source_params)
    if @source.save
      FetchSubstackSourceJob.perform_later(@source.id)
      redirect_to substack_posts_path, notice: "Source added — fetching posts in the background."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @source.destroy
    redirect_to substack_sources_path, notice: "Source removed."
  end

  private

  def set_source
    @source = current_user.substack_sources.find(params[:id])
  end

  def source_params
    params.require(:substack_source).permit(:feed_url, :name)
  end
end
