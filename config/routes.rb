SonicFlux::Application.routes.draw do

  root  'games#intro'
  
  get   "/signin",            to: 'sessions#new'
  get   "/signout",           to: 'sessions#destroy'
  get   "/signup",            to: 'users#new'

  get   "/intro",             to: 'games#intro'
  get   "/play",              to: 'games#play'
  get   "/progress/:id",      to: 'games#progress'
  get   "/leaders",           to: 'games#leaders'
  get   "/about",             to: 'games#about'
  post  "/firstquestion",     to: 'games#first_question'
  post  "/answer",            to: 'games#answer'
  post  "/round_started",     to: 'games#round_started'
  post  "/round_ended",       to: 'games#round_ended'
  post  "/change_difficulty", to: 'games#change_difficulty'

  resources   :sessions
  resources   :users
  resources   :results
  resources   :rounds
  resources   :question_occurrences
  resources   :questions
  resources   :question_types
  resources   :choices
  resources   :difficulty_levels

end
