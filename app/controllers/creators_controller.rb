class CreatorsController < ApplicationController
  before_action :set_creator, only: [ :show, :edit, :update ]

  # def show
  # end

  def new
    @creator = current_user.build_creator
  end

  def create
    @creator = current_user.build_creator(creator_params)
    if @creator.save
      redirect_to creator_path, notice: "Profile created!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @creator.update(creator_params)
      redirect_to creator_path, notice: "Profile updated!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def edit
  end
  private

  def set_creator
    @creator = current_user.creator
  end

  def creator_params
    params.require(:creators).permit(:name, :topic, :goal, :audience)
  end
end
