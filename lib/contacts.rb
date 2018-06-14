# Contacts hold on to several instances of "Contact" in a hash
class Contacts
  attr_reader :all_contacts
  
  def initialize(path)
    @all_contacts = generate_contacts(path) # {}
  end

  def user(nick_name)
    all_contacts[:nick_name]
  end

  def each
    all_contacts.each do |nick_name, details|
      yield(nick_name, details)
    end
  end
  
  private

  def generate_contacts(path)
    loaded_contacts_db = YAML.load_file(path)
    return {} if !loaded_contacts_db # return empty hash if no content in db

    loaded_contacts_db.each_with_object({}) do |(nick_name, details), hash|
      hash[nick_name] = Contact.new(details)
    end
  end
end

# Each "Contact" represents an individual contact with all it's information
class Contact
  attr_reader :details
  attr_accessor :nick_name, :full_name, :phone, :email
  
  def initialize(details)
    @all_details = details

    @full_name = details['full_name']
    @phone = details['phone'].to_s
    @email = details['email']
  end
end