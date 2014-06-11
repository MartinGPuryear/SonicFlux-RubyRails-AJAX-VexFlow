class RoundsController < ApplicationController

  #   Relatively standard boilerplate controller code.
  #   RESTful CRUD functionality, access limited to Admins.
  #   Used only to create/edit/destroy specific Round records, 
  #   e.g. for targeted SW testing of Leaderboard or Progress .

  before_action :require_admin
  before_action :set_not_playing #, only: [:index, :new, :show, :edit]

  def index
    @rounds = Round.all
  end

  def new
    @round = Round.new
  end

  def show
    @round = Round.find(params[:id])
  end

  def edit
    @round = Round.find(params[:id])
  end


  def create
    @round = Round.new(round_params)
    if @round.save
      redirect_to rounds_path, notice: "Round #{ @round.id.to_s } was successfully created."
    else
      flash.now[:errors] = @round.errors.messages
      render action: "new"
    end
  end

  def update
    round = Round.find(params[:id])
    r_input = params[:round]

    if round.update(num_participants:     r_input[:num_participants], 
                    difficulty_level_id:  r_input[:difficulty_level_id])
        redirect_to round, notice: "Round #{ round.id.to_s } was successfully updated."
    else
        flash[:errors] = round.errors.messages
        redirect_to edit_round_path(params[:id]) 
    end
  end

  def destroy
    round = Round.find(params[:id])
    
    if round.destroy == false
        flash[:errors] = round.errors.messages
    else
        flash[:notice] = "Round #{ params[:id] } was successfully deleted."
    end
    redirect_to rounds_path
  end


  private
  def round_params
    params.require(:round).permit(:num_participants, :difficulty_level_id)
  end  

end
