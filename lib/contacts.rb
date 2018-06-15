# Contacts hold on to several instances of "Contact" in a hash
class Contacts
  attr_reader :all_contacts
  
  def initialize(path)
    @all_contacts = load_contacts(path) # {}
  end

  def get_user(nick_name)
    @all_contacts[nick_name]
  end

  def each
    all_contacts.each do |nick_name, details|
      yield(nick_name, details)
    end
  end

  def add_contact(details)
    @all_contacts[details.delete('nick_name')] = Contact.new(details)
    binding.pry
  end

  def update(path)
    File.open(path, 'w') { |f| YAML.dump(@all_contacts, f) }
  end
  
  private

  def load_contacts(path)
    loaded_contacts_db = YAML.load_file(path)
    return {} if !loaded_contacts_db # return empty hash if no content in db
    loaded_contacts_db
  end
end

# Each "Contact" represents an individual contact with its information
class Contact
  attr_reader :details
  attr_accessor :nick_name, :full_name, :phone, :email, :address
  
  def initialize(details)
    @details = details

    @full_name = details['full_name']
    @phone = details['phone']
    @email = details['email']
    @address = details['address']
  end
end