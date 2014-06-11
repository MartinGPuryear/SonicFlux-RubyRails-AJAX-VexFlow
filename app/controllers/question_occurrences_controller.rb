class QuestionOccurrencesController < ApplicationController

  #   Relatively standard boilerplate controller code.
  #   RESTful CRUD functionality, access limited to Admins.
  #   Used only in the creation/edit of specific question sets
  #   e.g. for SW testing of specific questions/question_types.

  before_action :require_admin
  before_action :set_not_playing #, only: [:index, :new, :show, :edit]
  
  def index
    @question_occurrences = QuestionOccurrence.all
  end

  def new
    @question_occurrence = QuestionOccurrence.new
  end

  def show
    @question_occurrence = QuestionOccurrence.find(params[:id])
  end

  def edit
    @question_occurrence = QuestionOccurrence.find(params[:id])
  end


  def create
    @question_occurrence = QuestionOccurrence.new(question_occurrence_params)
    if @question_occurrence.save
      redirect_to question_occurrences_path, notice: "QuestionOccurrence #{ @question_occurrence.id.to_s } was successfully created."
    else
      flash.now[:errors] = @question_occurrence.errors.messages
      render action: "new"
    end
  end

  def update
    qo = QuestionOccurrence.find(params[:id])

    if qo.update(round_id:      params[:question_occurrence][:round_id], 
                question_id:    params[:question_occurrence][:question_id], 
                index_in_round: params[:question_occurrence][:index_in_round])
        redirect_to question_occurrence_path(params[:id]), notice: "QuestionOccurrence #{ qo.id.to_s } was successfully updated."
    else
        flash[:errors] = qo.errors.messages
        redirect_to edit_question_occurrence_path(params[:id]) 
    end
  end

  def destroy
    qo = QuestionOccurrence.find(params[:id])
    
    if qo.destroy == false
        flash[:errors] = qo.errors.messages
    else
        flash[:notice] = "QuestionOccurrence #{ params[:id] } was successfully deleted."
    end
    redirect_to question_occurrences_path
  end


  private
  def question_occurrence_params
    params.require(:question_occurrence).permit(:round_id, :question_id, :index_in_round)
  end  
end
