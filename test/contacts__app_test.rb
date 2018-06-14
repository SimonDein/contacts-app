ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'
require 'fileutils'
require 'yaml'

require_relative '../contacts_app.rb'


class TestContactsApp < Minitest::Test
  include Rack::Test::Methods
  
  def app
    Sinatra::Application
  end

  # Sets up DB with a single contact entry as base
  def setup
    test_contact = <<~CONTACT
    ---
    Champ:
      full_name: Muhammed Ali
      phone: 12345678
      email: muhammed@boxer.com
    CONTACT
    
    FileUtils.mkdir('test/data')
    File.open('test/data/contacts_db.yaml', 'w') do |f|
      f.write(test_contact)
    end
  end

  # Destroys DB
  def teardown
    FileUtils.rm_rf('test/data')
  end
  
  def test_contacts_page
    get '/contacts'

    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'Champ')
  end
end