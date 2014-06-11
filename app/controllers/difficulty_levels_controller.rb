class DifficultyLevelsController < ApplicationController

  #   Relatively standard boilerplate controller code.
  #   RESTful CRUD functionality, access limited to Admins.
  #   Used only in the process of creating/editing difficulty levels,
  #   e.g. beginner, intermediate, advanced, expert.  
  #   Initially we support these four, but more are always possible.

  before_action :require_admin
  before_action :set_not_playing #, only: [:index, :new, :show, :edit]
  
  def index
    @difficulty_levels = DifficultyLevel.all
  end

  def new
    @difficulty_level = DifficultyLevel.new
  end

  def show
    @difficulty_level = DifficultyLevel.find(params[:id])
  end

  def edit
    @difficulty_level = DifficultyLevel.find(params[:id])
  end


  def create
    @difficulty_level = DifficultyLevel.new(difficulty_level_params)
    if @difficulty_level.save
      redirect_to difficulty_levels_path, notice: "DifficultyLevel #{ @difficulty_level.id.to_s } was successfully created."
    else
      flash.now[:errors] = @difficulty_level.errors.messages
      render action: "new"
    end
  end

  def update
    dl = DifficultyLevel.find(params[:id])

    if dl.update(desc: params[:difficulty_level][:desc])
        redirect_to difficulty_level_path(params[:id]), notice: "DifficultyLevel #{ dl.id.to_s } was successfully updated."
    else
        flash[:errors] = dl.errors.messages
        redirect_to edit_difficulty_level_path(params[:id]) 
    end
  end

  def destroy
    dl = DifficultyLevel.find(params[:id])
    
    if dl.destroy == false
        flash[:errors] = dl.errors.messages
    else
        flash[:notice] = "DifficultyLevel #{ params[:id] } was successfully deleted."
    end
    redirect_to difficulty_levels_path
  end


  private
  def difficulty_level_params
    params.require(:difficulty_level).permit(:desc)
  end  
end
