require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/contrib'
require 'erubis'
require 'bcrypt'
require 'yaml'
require 'pry'

require_relative 'lib/contacts.rb'

=begin
##################################
############### TODO #############
##################################

- Sign up

- Profile pictures

- Sort contacts by alphabetical order
  - ascending or descending

FURTHER DEVELOPMENT
- Search function
    - ajax

- Show address on google maps
=end

configure do
  disable :logging # to no show double loggin entries in output
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

#########################################################
######################## METHODS ########################
#########################################################

def data_path
  case ENV['RACK_ENV']
  when 'test'
    "test/data/#{session[:user_name]}/contacts_db.yaml"
  else
    "data/#{session[:user_name]}/contacts_db.yaml"
  end
end

def valid_credentials?(user_name, entered_password)
  credentials = load_credentials

  if credentials.has_key?(user_name)
    encrypted_password = BCrypt::Password.new(credentials[user_name])
    encrypted_password == entered_password
  else
    false
  end
end

def load_credentials
  YAML.load_file(credentials_path)
end

def credentials_path
  if ENV['RACK_ENV'] == 'test'
    File.expand_path('../test/users.yaml' ,__FILE__)
  else
    File.expand_path('..//users.yaml' ,__FILE__)
  end
end

def require_user_logged_in
  if !session[:user_name]
    session[:error] = 'You need to be logged in to do that!'
    redirect '/login' unless session[:user_name]
  end
end

def fetch_profile_picture
  "/data/no_profile_picture.jpg"
end

#########################################################
######################## ROUTES #########################
#########################################################
get '/' do
  redirect '/contacts'
  # redirect to '/login' if user not logged in
end

get '/login' do
  erb :login, layout: :layout
end

get '/logout' do
  session.delete('user_name')
  redirect '/login'
end

# View all contacts
get '/contacts' do
  require_user_logged_in
  
  @contacts = Contacts.new(data_path)

  erb :contacts, layout: :layout
end

# View "contact"
get '/contacts/add' do
  require_user_logged_in
  
  erb :add_contact, layout: :layout
end

# View edit contact
get '/contacts/edit/:id' do
  require_user_logged_in

  @id = params[:id]
  @contact = Contacts.new(data_path).get_user(@id)
  
  erb :edit_contact, layout: :layout
end

# View specific contact
get '/contacts/:id' do
  require_user_logged_in

  @id = params[:id]
  @contact = Contacts.new(data_path).get_user(@id)

  erb :view_contact, layout: :layout
end

# Delete a contact
get '/contacts/delete/:id' do
  require_user_logged_in

  id = params[:id]
  contacts = Contacts.new(data_path)
  nick_name = contacts.get_user(id).nick_name

  contacts.remove_contact(id)
  contacts.update!(data_path)

  session[:success] = "The contact '#{nick_name}' has been removed."
  redirect '/contacts'
end

# Submit added contact
post '/contacts/add' do
  if params[:nick_name].empty?
    session[:error] = "You didn't provide a name for the contact."
    erb :add_contact, layout: :layout
  else
    contacts = Contacts.new(data_path)
    contacts.add_contact(params)
    contacts.update!(data_path)

    session[:success] = "'#{params[:nick_name]}' has been added to contacts."
    redirect '/contacts'
  end
end

# Submit edited contact
post '/contacts/edit/:id' do
  id = params[:id]
  nick_name = params[:nick_name]
  
  if nick_name.empty?
    session[:error] = "You must provide a nick name"
    erb :edit_contact, layout: :layout
  else
    contacts = Contacts.new(data_path)
    contacts.update_contact(id, params)
    contacts.update!(data_path)
    session[:success] = "'#{nick_name}' has been updated"
    redirect '/contacts'
  end
end

post '/login' do
  user_name = params[:user_name]
  password = params[:password]

  if valid_credentials?(user_name, password)
    session[:user_name] = user_name
    session[:success] = "You successfully logged in as '#{user_name}'"
    redirect '/contacts'
  else
    session[:error] = "Sorry, invalid credentials. Please try again."
    erb :login, layout: :layout
  end
end