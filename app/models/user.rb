class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_one :creator
  has_many :ideas, dependent: :destroy

  def onboarding_complete?
    next_onboarding_step == :done
  end

  def next_onboarding_step
    return :creator unless creator.present?
    return :idea    unless ideas.any?
    return :script  unless Script.where(idea: ideas).exists?
    return :post    unless LinkedinPost.where(script: Script.where(idea: ideas)).exists?

    :done
  end
end
