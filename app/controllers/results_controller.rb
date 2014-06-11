class ResultsController < ApplicationController

  #   Relatively standard boilerplate controller code.
  #   RESTful CRUD functionality, access limited to Admins.
  #   Used only to create/edit/destroy specific Result records, 
  #   e.g. for targeted SW testing of Leaderboard or Progress .

  before_action :require_admin
  before_action :set_not_playing #, only: [:index, :new, :show, :edit]
  
  def index
    @results = Result.all
  end

  def new
    @result = Result.new
  end

  def show
    @result = Result.find(params[:id])
  end

  def edit
    @result = Result.find(params[:id])
  end


  def create
    @result = Result.new(result_params)
    if @result.save
      redirect_to results_path, notice: "Result #{ @result.id.to_s } was successfully created."
    else
      flash.now[:errors] = @result.errors.messages
      render action: "new"
    end
  end

  def update
    r = Result.find(params[:id])
    r_input = params[:result]

    if r.update(num_correct:    r_input[:num_correct], 
                num_skipped:    r_input[:num_skipped], 
                num_incorrect:  r_input[:num_incorrect], 
                points:         r_input[:points], 
                rank:           r_input[:rank], 
                round_complete: r_input[:round_complete], 
                round_id:       r_input[:round_id], 
                user_id:        r_input[:user_id])
        redirect_to result_path(params[:id]), notice: "Result #{ r.id.to_s } was successfully updated."
    else
        flash[:errors] = r.errors.messages
        redirect_to edit_result_path(params[:id]) 
    end
  end

  def destroy
    r = Result.find(params[:id])
    
    if r.destroy == false
        flash[:errors] = r.errors.messages
    else
        flash[:notice] = "Result #{ params[:id] } was successfully deleted."
    end
    redirect_to results_path
  end


  private
  def result_params
    params.require(:result).permit(:num_correct, :num_skipped, :num_incorrect, :points, :rank, :round_complete, :round_id, :user_id)
  end  
end
