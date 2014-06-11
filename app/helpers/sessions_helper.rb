module SessionsHelper

  #   SessionsHelper provides numerous utility functions for tracking
  #   the current user, creating the subset of the User object that is 
  #   passable to views (e.g. without the password). It also contains
  #   functions to check if session is signed in, if the signed-in user 
  #   is an admin, and if user can access user-specific info 

  #   TODO: implement this as a DB field, not a hard-coded user_id. 
    # As written, will break if user_id values change (e.g. when
    # migrating the DB from dev't to test or prod)
  ADMIN_USER_ID = 9

private
  #   Set the current user instance var. Only called by sign_in/sign_out.
  def current_user=(user)
    @current_user = user
  end
public
  #   Retrieve the signed-in user (might differ from user being viewed)
  def current_user
    return User.find(session[:user_id]) if session[:user_id]
  end

  #   User has successfully authenticated. Complete the sign-in process.
  def sign_in(user)
    session[:user_id] = user.id
    self.current_user = user
    session[:playing] = false
  end
  #   User requested sign-out. Clear out the fields used to track signin.
  def sign_out
    session[:user_id] = nil
    self.current_user = nil
    session[:playing] = nil
  end

  #   public_user is the subset of User that is safe to pass to views.
    # Returns nil if not signed in. For the passed-in ID (current_user, 
    # if no param passed), retrieve only ID, tag and difficulty level. 
    # Specifically we exclude *password_digest*, although created_at, 
    # updated_at, etc (eventually facebook_id) are irrelevant anyway.
  def public_user(user_id=nil)
    if user_id.nil?
      if @public_user
        puts "public_user before: #{@public_user.difficulty_level_id} ***************************************************************************************"
      end
      @public_user ||= User.select("id, player_tag, difficulty_level_id").find(session[:user_id]) if session[:user_id]
      puts "public_user.diff_lvl after: #{@public_user.difficulty_level_id} ***************************************************************************************"
    else
      if @public_user
        puts "public_user.diff_lvl before: #{@public_user.difficulty_level_id} ***************************************************************************************"
      end
      @public_user ||= User.select("id, player_tag, difficulty_level_id").find(user_id)
      puts "public_user.diff_lvl after: #{@public_user.difficulty_level_id} ***************************************************************************************"
    end
    return @public_user
  end

  #   Are we signed in? Note: gameplay as guest is not yet enabled.
  def signed_in?
    !current_user.nil?
  end
  #   Notify client: the requested view requires signin. Redirect there. 
  def deny_access
    redirect_to signin_path, notice: "Please sign in to go there."
  end
  #   If signed in, continue on. Otherwise, redirect to signin.
  def require_signin
    deny_access unless signed_in?
  end

  #   Is this user "you"? Restrict access to user-specific data.
  def current_user?(user)
    user == current_user 
  end
  #   Notify: user can't access the requested view. Redirect to profile
  def deny_wrong_user
    redirect_to user_path(session[:user_id]), alert: "Sorry, access restricted to that specific user only."
  end
  #   Only allow access if you are the specified user.
    # First require a signed-in client. Also, require either the 
    # specified user or Admin. If either case fails, redirect to signin.
  def require_current_user(user)
    if !signed_in?
      deny_access
    elsif (!current_user?(user) && !current_user_admin?)
      deny_wrong_user
    end
  end

  #   Is current_user an Admin? Check before accessing user-specific data.
  def current_user_admin?
    signed_in? && (ADMIN_USER_ID == session[:user_id])
  end
  #   Notify: only admins can access the requested info. Redirect.
  def deny_admin_access
    redirect_to user_path(session[:user_id]), alert: "Sorry, access restricted to administrators only." 
  end
  #   If admin, continue on. Otherwise, redirect to profile.
  def require_admin
    if !signed_in?
      deny_access
    elsif !current_user_admin?
      deny_admin_access
    end
  end

end
