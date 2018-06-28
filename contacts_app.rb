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
- Edit contact

- Sign in
  - if logged in
      - redirect to contacts
  - else
      - redirect to login

- Search function
    - ajax
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

# View all contacts
get '/contacts' do
  @contacts = Contacts.new(data_path)

  erb :contacts, layout: :layout
end

# View "contact"
get '/contacts/add' do

  # make sure to capitalize names
  
  erb :add_contact, layout: :layout
end

# View edit contact
get '/contacts/edit/:nick_name' do
  @nick_name = params[:nick_name]
  contact = Contacts.new(data_path).get_user(@nick_name)
  
  @full_name = contact.full_name
  @email = contact.email
  @phone = contact.phone
  @adress = contact.address
  
  erb :edit_contact, layout: :layout
end

# View specific contact
get '/contacts/:nick_name' do
  @nick_name = params[:nick_name]
  
  contacts = Contacts.new(data_path)
  @contact = contacts.get_user(@nick_name)

  erb :view_contact, layout: :layout
end

# Submit added contact
post '/contacts/add' do
  nick_name = params[:nick_name]
  if nick_name.empty?
    session[:error] = "You didn't provide a name for the contact."
    erb :add_contact, layout: :layout
  else
    contacts = Contacts.new(data_path) # load contacts
    contacts.add_contact(params) # add contact
    contacts.update(data_path) # update contacts (save to yaml bts)
    session[:success] = "'#{nick_name}' added to contacts."
    redirect '/contacts'
  end
end

# Submit edited contact
post '/contacts/edit/:old_nick_name' do
  nick_name = params[:nick_name]
  if nick_name.empty?
    session[:error] = "You left 'nick name' empty."
    erb :edit_contact, layout: :layout
  else
    contacts = Contacts.new(data_path) # load contacts
    binding.pry
    contacts.add_contact(params) # add contact
    contacts.update(data_path) # update contacts (save to yaml bts)
    session[:success] = "'#{nick_name}' has been updated"
    redirect '/contacts'
  end
end