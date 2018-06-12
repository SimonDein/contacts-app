require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/contrib'
require 'erubis'
require 'bcrypt'
require 'yaml'
require 'pry'

require_relative 'lib/contacts.rb'

configure do
  disable :logging # to no show double loggin entries in output
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

=begin
############### TODO ##########
###############################

- Define a ruby object oriented interface for contacts

- Index page
  - if logged in
      - redirect to contacts
  - else
      - redirect to login

- Contacts page
  - Let contacts show
  


=end

#########################################################
######################## METHODS ########################
#########################################################

def load_yaml(file)
  YAML.load_file(file)
end

#########################################################
######################## ROUTES #########################
#########################################################
get '/' do
  redirect '/contacts'
  # redirect to '/login' if user not logged in
end

get '/login' do
end

get '/contacts' do
  @contacts_data = load_yaml('data/contacts_db.yaml')
  @contacts = Contacts.new(@contacts_data)

  
  binding.pry

  erb :contacts, layout: :layout
end