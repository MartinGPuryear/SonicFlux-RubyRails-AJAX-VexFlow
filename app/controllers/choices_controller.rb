class ChoicesController < ApplicationController

  #   Relatively standard boilerplate controller code.
  #   RESTful CRUD functionality, access limited to Admins
  #   Used only in the question/choice creation/edit process

  before_action :require_admin
  before_action :set_not_playing #, only: [:index, :new, :show, :edit]

  def index
    @choices = Choice.all
  end

  def new
    @choice = Choice.new
  end

  def show
    @choice = Choice.find(params[:id])
  end

  def edit
    @choice = Choice.find(params[:id])
  end


  def create
    @choice = Choice.new(choice_params)
    if @choice.save
      redirect_to choices_path, notice: "Choice #{ @choice.id } was successfully created."
    else
      flash.now[:errors] = @choice.errors.messages
      render action: "new"
    end
  end

  def update
    c = Choice.find(params[:id])

    if c.update(choice_type:params[:choice][:choice_type], 
                prompt:     params[:choice][:prompt], 
                content:    params[:choice][:content])
        redirect_to choice_path(params[:id]), notice: "Choice #{ c.id.to_s } was successfully updated."
    else
        flash[:errors] = c.errors.messages
        redirect_to edit_choice_path(params[:id]) 
    end
  end

  def destroy
    c = Choice.find(params[:id])
    
    if c.destroy == false
        flash[:errors] = c.errors.messages
    else
        flash[:notice] = "Choice #{ params[:id] } was successfully deleted."
    end
    redirect_to choices_path
  end


  private
  def choice_params
    params.require(:choice).permit(:choice_type, :prompt, :content)
  end  
end
