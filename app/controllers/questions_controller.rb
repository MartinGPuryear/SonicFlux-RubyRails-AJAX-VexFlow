class QuestionsController < ApplicationController

  #   Relatively standard boilerplate controller code.
  #   RESTful CRUD functionality, access limited to Admins.
  #   Used only in the question creation/edit process.
  #   Initially we support only a single question_type value: 
  #   music notation OUT, multiple choice IN.

  before_action :require_admin
  before_action :set_not_playing #, only: [:index, :new, :show, :edit]
  
  def index
    @questions = Question.all
  end

  def new
    @question = Question.new
  end

  def show
    @question = Question.find(params[:id])
  end

  def edit
    @question = Question.find(params[:id])
  end


  def create
    @question = Question.new(question_params)
    if @question.save
      redirect_to questions_path, notice: "Question #{ @question.id.to_s } was successfully created."
    else
      flash.now[:errors] = @question.errors.messages
      render action: "new"
    end
  end

  def update
    q = Question.find(params[:id])
    q_input = params[:question]

    if q.update(question_type_id:     q_input[:question_type_id], 
                choice_type:          q_input[:choice_type], 
                difficulty_level_id:  q_input[:difficulty_level_id], 
                content:              q_input[:content], 
                correct_choice_id:    q_input[:correct_choice_id], 
                close_choice_id:      q_input[:close_choice_id])
        redirect_to question_path(params[:id]), notice: "Question #{ q.id.to_s } was successfully updated."
    else
        flash[:errors] = q.errors.messages
        redirect_to edit_question_path(params[:id]) 
    end
  end

  def destroy
    q = Question.find(params[:id])
    
    if q.destroy == false
        flash[:errors] = q.errors.messages
    else
        flash[:notice] = "Question #{ params[:id] } was successfully deleted."
    end
    redirect_to questions_path
  end


  private
  def question_params
    params.require(:question).permit(:question_type_id, :choice_type, :difficulty_level_id, :content, :correct_choice_id, :close_choice_id)
  end  
end
