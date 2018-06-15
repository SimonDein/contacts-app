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

def data_path
  case ENV['RACK_ENV']
  when 'test'
    'test/data/contacts_db.yaml'
  else
    'data/contacts_db.yaml'
  end
end

def titleize(str)
  str.split.map(&:capitalize).join(' ')
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
  @contacts = Contacts.new(data_path)

  erb :contacts, layout: :layout
end

get '/contacts/add' do

  # make sure to capitalize names
  
  erb :add_contact, layout: :layout
end

get '/contacts/:nick_name' do
  @nick_name = params[:nick_name]
  
  contacts = Contacts.new(data_path)
  @contact = contacts.get_user(@nick_name)

  erb :view_contact, layout: :layout
end


post '/contacts/add' do
  if params[:nick_name].empty?
    erb :add_contact, layout: :layout
  else
    contacts = Contacts.new(data_path) # load contacts
    contacts.add_contact(params) # add contact
    contacts.update(data_path) # update contacts (save to yaml bts)
    redirect '/contacts'
  end
end