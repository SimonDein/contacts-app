require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/contrib'
require 'erubis'
require 'bcrypt'
require 'yaml'
require 'pry'
require 'fileutils'

require_relative 'lib/contacts.rb'

=begin
##################################
############### TODO #############
##################################


##### FURTHER DEVELOPMENT
- Profile pictures

- Sort contacts by alphabetical order
  - ascending or descending

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
    File.expand_path('../test/data' ,__FILE__)
  else
    File.expand_path('../data' ,__FILE__)
  end
end

def user_data_path
  data_path + "/#{session[:user_name]}/contacts_db.yaml"
end

def credentials_path
  if ENV['RACK_ENV'] == 'test'
    File.expand_path('../test/users.yaml' ,__FILE__)
  else
    File.expand_path('..//users.yaml' ,__FILE__)
  end
end

def load_credentials
  credentials = YAML.load_file(credentials_path)
  return {} if credentials == false
  credentials
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

def user_logged_in?
  session[:user_name]
end

def require_user_logged_in
  if !user_logged_in?
    session[:error] = 'You need to be logged in to do that!'
    redirect '/login'
  end
end

def user_name_taken?(user_name)
  credentials = load_credentials
  credentials.has_key?(user_name)
end

def user_name_contain_spaces?(user_name)
  user_name.split.join != user_name
end

def user_name_contains_non_alphanumeric_characters(user_name)
  user_name =~ /[^a-zA-Z\d_]/
end

def detect_sign_up_error(user_name, password)
  case
  when user_name_taken?(user_name)
    "Sorry, the username has already been taken."
  when user_name.strip.length < 1
    "The username must at least contain a character"
  when user_name_contain_spaces?(user_name)
    "The username can't contain any spaces."
  when user_name_contains_non_alphanumeric_characters(user_name)
    "The username can only consist of alphanumeric characters and '_' (underscore)"
  when password.strip.length != password.length
    "The password can't lead or end with a space."
  end
end

def encrypt_password(password)
  BCrypt::Password.create(password)
end

def create_user!(user_name, password)
  credentials = load_credentials
  credentials[user_name] = encrypt_password(password)

  File.open(credentials_path, "r+") do |f|
    f.write(credentials.to_yaml)
  end

  # Setup user directory and file for contacts
  FileUtils.mkdir_p(data_path + "/#{user_name}")
  FileUtils.touch(data_path + "/#{user_name}/contacts_db.yaml")
end

def remove_user!(user_name)
  FileUtils.rm_rf(data_path + "/#{user_name}")
  loaded_credentials = load_credentials
  loaded_credentials.delete(user_name)
  File.open(credentials_path, 'w') { |f| YAML.dump(loaded_credentials, f) }
end

def return_if_contact_does_not_exist(contact)
  if contact.nil?
    session[:error] = "Sorry, it seems like the contact doesn't exist."
    redirect '/contacts'
  end
end

#########################################################
######################## ROUTES #########################
#########################################################
# redirect to '/login' if user not logged in
get '/' do
  if user_logged_in?
    redirect '/contacts'
  else
    redirect '/login'
  end
end

get '/login' do
  erb :login, layout: :layout
end

get '/signup' do
  erb :signup, layout: :layout
end

get '/logout' do
  session.delete('user_name')
  redirect '/login'
end

# View all contacts
get '/contacts' do
  require_user_logged_in
  
  @contacts = Contacts.new(user_data_path)

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
  @contact = Contacts.new(user_data_path).get_user(@id)

  return_if_contact_does_not_exist(@contact)
  
  @nick_name = @contact.nick_name
  @full_name = @contact.full_name
  @email = @contact.email
  @phone = @contact.phone
  @address = @contact.address
  
  erb :edit_contact, layout: :layout
end

# View specific contact
get '/contacts/:id' do
  require_user_logged_in
  
  @id = params[:id]
  @contact = Contacts.new(user_data_path).get_user(@id)

  return_if_contact_does_not_exist(@contact)

  erb :view_contact, layout: :layout
end

# Delete a contact
get '/contacts/delete/:id' do
  require_user_logged_in

  id = params[:id]
  contacts = Contacts.new(user_data_path)
  contact = contacts.get_user(id)
  return_if_contact_does_not_exist(contact)
  
  nick_name = contact.nick_name

  contacts.remove_contact!(id)

  session[:success] = "The contact '#{nick_name}' has been removed."
  redirect '/contacts'
end

# Submit added contact
post '/contacts/add' do
  @nick_name = params[:nick_name]
  @full_name = params[:full_name]
  @email = params[:email]
  @phone = params[:phone]
  @address = params[:address]
  
  if params[:nick_name].empty?
    session[:error] = "You didn't provide a name for the contact."
    erb :add_contact, layout: :layout
  else
    contacts = Contacts.new(user_data_path)
    contacts.add_contact!(params)

    session[:success] = "'#{params[:nick_name]}' has been added to contacts."
    redirect '/contacts'
  end
end

# Submit edited contact
post '/contacts/edit/:id' do
  @nick_name = params[:nick_name]
  @full_name = params[:full_name]
  @email = params[:email]
  @phone = params[:phone]
  @address = params[:address]
  
  id = params[:id]
  
  if @nick_name.empty?
    session[:error] = "You must provide a nick name"
    erb :edit_contact, layout: :layout
  else
    contacts = Contacts.new(user_data_path)
    contacts.update_contact!(id, params)
    session[:success] = "'#{@nick_name}' has been updated."

    redirect '/contacts'
  end
end

post '/login' do
  @user_name = params[:user_name].strip
  @password = params[:password]

  if valid_credentials?(@user_name, @password)
    session[:user_name] = @user_name
    session[:success] = "You are now logged in as '#{@user_name}'"
    redirect '/contacts'
  else
    session[:error] = "Sorry, invalid credentials. Please try again."
    erb :login, layout: :layout
  end
end

post '/signup' do
  @user_name = params[:user_name]
  @password = params[:password]

  sign_up_error = detect_sign_up_error(@user_name, @password)
  if sign_up_error
    session[:error] = sign_up_error
    erb :signup, layout: :layout
  else
    create_user!(@user_name, @password)
    session[:success] = "The user '#{@user_name}' was created.\nPlease log in."
    redirect '/login'
  end
end