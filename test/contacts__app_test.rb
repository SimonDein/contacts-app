ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'
require 'fileutils'
require 'yaml'
require 'pry'
require 'bcrypt'

require_relative '../contacts_app.rb'


class TestContactsApp < Minitest::Test
  include Rack::Test::Methods

  ###########################################################################
  ############################### UTILITIES #################################
  ###########################################################################
  def app
    Sinatra::Application
  end

  def setup
    create_user!('bob', '1234')
  end

  def teardown
    remove_user!('bob')
  end

  def session
    last_request.env['rack.session']
  end

  def admin_session
    {"rack.session" => {user_name: 'bob'} }
  end

  ###########################################################################
  ################################# TESTS ###################################
  ###########################################################################
  def test_view_login_page
    get '/login'

    assert_equal(200, last_response.status)
    assert_includes(last_response.body, "<h1>Login</h1>")
  end

  def test_view_contacts_without_login
    get '/contacts'

    assert_equal(302, last_response.status)
    assert_equal('You need to be logged in to do that!', session[:error])
    
    get last_response['Location']
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, "<h1>Login</h1>")
  end

  def test_login_with_valid_credentials
    post '/login', {user_name: 'jessie', password: 'letmein!'}

    assert_includes(last_response.body, 'Sorry, invalid credentials. Please try again')
    assert_includes(last_response.body, 'User Name')
    assert_includes(last_response.body, 'Password')
  end
  
  def test_login_with_valid_user_name_and_invalid_password
    post '/login', {user_name: 'bob', password: 'blop'}

    assert_includes(last_response.body, 'Sorry, invalid credentials. Please try again')
    assert_includes(last_response.body, 'User Name')
    assert_includes(last_response.body, 'Password')
  end

  def test_login_with_invalid_user_name_and_valid_password
    post '/login', {user_name: 'bobby', password: '1234'}

    assert_includes(last_response.body, 'Sorry, invalid credentials. Please try again')
    assert_includes(last_response.body, 'User Name')
    assert_includes(last_response.body, 'Password')
  end

  def test_login_with_valid_credentials
    post '/login', {user_name: 'bob', password: '1234'}
    
    assert_equal(302, last_response.status)
    assert_equal("You are now logged in as 'bob'", session[:success])
  end

  def test_view_sign_up
    get '/signup'
    assert_includes(last_response.body, '<h1>Sign Up</h1>')
  end

  def test_sign_up_with_taken_user_name
    post 'signup', {user_name: 'bob', password: 'somepass'}

    assert_includes(last_response.body, 'Sorry, the username has already been taken.')
  end

  def test_sign_up_with_zero_length_user_name
    post 'signup', {user_name: '', password: 'somepass'}

    assert_includes(last_response.body, 'The username must at least contain a character')
  end

  def test_sign_up_with_non_alphanumeric_characters_in_username
    post 'signup', {user_name: 'User/-$', password: 'somepass'}

    assert_includes(last_response.body, "The username can only consist of alphanumeric characters and '_' (underscore)")
  end

  def test_sign_up_with_spaces_in_username
    post 'signup', {user_name: 'pedro is king', password: 'somepass'}

    assert_includes(last_response.body, "The username can't contain any spaces.")
  end
  
  def test_sign_up_with_leading_space
    post 'signup', {user_name: 'pikachu', password: ' thunder'}

    assert_includes(last_response.body, "The password can't lead or end with a space.")
  end

  def test_sign_up_with_valid_credentials
    post 'signup', {user_name: 'Valid_Username', password: 'Ba//Li$'}
    
    assert_equal(302, last_response.status)
    assert_equal("The user 'Valid_Username' was created.\nPlease log in.", session[:success])

    remove_user!('Valid_Username')
  end

  def test_view_contacts
    get '/contacts', {}, admin_session

    assert_includes(last_response.body, '<h1>Contacts</h1>')
    assert_includes(last_response.body, '+ Add Contact')
  end
  
  def test_logout
    get '/contacts', {}, admin_session
    assert_includes(last_response.body, '<h1>Contacts</h1>')
    
    get '/logout'
    assert_equal(302, last_response.status)

    get last_response["Location"]
    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'Login')
  end
end