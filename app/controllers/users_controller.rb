class UsersController < ApplicationController

  #   Manages the creation and update of user registrations, as
  #   well as gamer profiles.  Correspondingly, 
  #   - Creating an acct uses :new and :create.  
  #   - Viewing a profile uses :show.
  #   - Editing a profile uses :edit and :update.
  #  
  #   Currently, Admin access is required for the remaining 
  #   RESTful CRUD functionality (:index, and :destroy).  
  #   Unlike the Session object, the User object IS backed by a model.  

  #   session_helper provides numerous companion functions for tracking
  #   the current user, creating a subset of the User object that is 
  #   passable to views (e.g. without the password). Also contains
  #   functions for checking whether user is logged, whether current user 
  #   is admin, or whether user "owns" the user-specific views requested. 

  before_action :require_admin, only: [:index, :destroy]
  before_action :require_signin, only: [:show, :edit, :update]
  before_action :set_not_playing, only: [:index, :new, :show, :edit]
  
  def index
    @users = User.all.select(:id, :player_tag, :difficulty_level_id, :created_at)
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      redirect_to @user, notice: 'User was successfully created.'
    else
      flash.now[:errors] = @user.errors.messages
      render action: "new"
    end
  end

  def show
    @user = User.find(params[:id])
  end

  def edit
    @user = User.find(params[:id])
    require_current_user(@user)
  end

  def update
    user = User.find(params[:id])
    require_current_user(user)

    user_input = params[:user]

    if user.update(player_tag: user_input[:player_tag], 
                   password: user_input[:password], 
                   password_confirmation: user_input[:password_confirmation], 
                   difficulty_level_id: user_input[:difficulty_level_id])
        redirect_to user, notice: 'User was successfully updated.'
    else
        flash[:errors] = user.errors.messages
        redirect_to edit_user_path(params[:id]) 
    end
  end

  def destroy
    u = User.find(params[:id])
    
    if current_user?(u)
        flash[:error] = "Please don't destroy yourself - it isn't healthy!"
    elsif u.destroy == false
        flash[:errors] = u.errors.messages
    end
    redirect_to users_path
  end


  private
  def user_params
    params.require(:user).permit(:player_tag, :difficulty_level_id, :password, :password_confirmation)
  end

end
