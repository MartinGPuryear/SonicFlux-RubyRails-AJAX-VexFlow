
# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Initialize the Rails application.
SonicFlux::Application.initialize!

include GamesHelper

run_startup_code

puts "\n***** completed app-specific initialization in environment.rb *****\n\n\n"
