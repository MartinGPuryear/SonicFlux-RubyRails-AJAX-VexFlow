class ApplicationController < ActionController::Base

  #   Umbrella controller for the SonicFlux Rails app
  #   Game-specific functions are in GamesController

  #   Prevent CSRF attacks by raising an exception.
  #   For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  #   includes helper functions related to signin and identity
  include SessionsHelper

  #   includes helper functions related to gameplay state
  include GamesHelper

end
