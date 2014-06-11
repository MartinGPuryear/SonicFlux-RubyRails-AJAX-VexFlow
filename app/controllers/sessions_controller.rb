class SessionsController < ApplicationController

  #   Manages the signin/signout process for already-registered users.
  #   For regular users, only :new and :create are used.  
  # 
  #   Additional RESTful CRUD functionality is linmited to Admins.  
  #   Note that the Session object is not backed by a model.  
  #   Corresondingly, anything beyond :new and :create is currently
  #   boilerplate code and not yet providing value. 
  #   Possible future features: (index) listing those currently signed-in, 
  #   (show) details about a session, or (destroy) forcing a signoff.  

  #   SessionsHelper provides numerous companion functions for tracking
  #   the current user, creating a subset of the User object that is 
  #   passable to views (e.g. without the password). Also contains
  #   functions for checking whether user is logged, whether current user 
  #   is admin, or whether user "owns" the user-specific views requested. 

  #   TODO: Facebook login, allowing a user to use FB authentication
  #   instead of our signin mechanism.  

  before_action :require_admin, only: [:index, :show, :edit, :update]
  before_action :set_not_playing, only: [:index, :new, :show, :edit, :destroy]
  
  def index
  end

  def new
  end

  def create
    user = User.find_by(player_tag: params[:session][:player_tag]).try(:authenticate, params[:session][:password])

    if !user
      flash.now[:errors] = { Invalid: ["player tag/password combination."] }
      render :new
    else
      sign_in user

      redirect_to play_path
    end
  end

  def show
  end

  def edit
  end

  def update
  end

  def destroy
    sign_out
    redirect_to signin_path
  end

end
