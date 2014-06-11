class QuestionTypesController < ApplicationController

  #   Relatively standard boilerplate controller code.
  #   RESTful CRUD functionality, access limited to Admins.
  #   Used only in the process of creating new question types,
  #   e.g. audio output, or audio input, or free text input.  
  #   Initially we support only a single question_type value: 
  #   music notation OUT, multiple choice IN.

  before_action :require_admin
  before_action :set_not_playing #, only: [:index, :new, :show, :edit]
  
  def index
    @question_types = QuestionType.all
  end

  def new
    @question_type = QuestionType.new
  end

  def show
    @question_type = QuestionType.find(params[:id])
  end

  def edit
    @question_type = QuestionType.find(params[:id])
  end


  def create
    @question_type = QuestionType.new(question_type_params)
    if @question_type.save
      redirect_to question_types_path, notice: "QuestionType #{ @question_type.id.to_s } was successfully created."
    else
      flash.now[:errors] = @question_type.errors.messages
      render action: "new"
    end
  end

  def update
    qt = QuestionType.find(params[:id])

    if qt.update(prompt: params[:question_type][:prompt])
        redirect_to question_type_path(params[:id]), notice: "QuestionType #{ qt.id.to_s } was successfully updated."
    else
        flash[:errors] = qt.errors.messages
        redirect_to edit_question_type_path(params[:id]) 
    end
  end

  def destroy
    qt = QuestionType.find(params[:id])
    
    if qt.destroy == false
        flash[:errors] = qt.errors.messages
    else
        flash[:notice] = "QuestionType #{ params[:id] } was successfully deleted."
    end
    redirect_to question_types_path
  end


  private
  def question_type_params
    params.require(:question_type).permit(:prompt)
  end  
end
