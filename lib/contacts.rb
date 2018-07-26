# Contacts hold on to several instances of "Contact" in a hash
class Contacts
  attr_reader :all_contacts, :path

  def initialize(path)
    @path = path
    @all_contacts = load_contacts(path) # {}
  end

  def get_user(id)
    all_contacts[id.to_i]
  end

  def remove_contact!(id)
    all_contacts.delete(id.to_i)

    update_contacts!
  end

  def add_contact!(details)
    id = detect_next_id
    @all_contacts[id] = Contact.new(details)
    
    update_contacts!
  end

  def update_contact!(id, details)
    @all_contacts[id.to_i] = Contact.new(details)

    update_contacts!
  end

  def each
    all_contacts.each do |id, details|
      yield(id, details)
    end
  end

  private

  def update_contacts!
    File.open(@path, 'w') { |f| YAML.dump(@all_contacts, f) }
  end

  def detect_next_id
    return 1 if @all_contacts.empty?
    
    current_max_id = @all_contacts.keys.max
    current_max_id + 1
  end

  def load_contacts(path)
    loaded_contacts_db = YAML.load_file(path)
    return {} if !loaded_contacts_db # return empty hash if no content in db
    loaded_contacts_db
  end
end

# Each "Contact" represents an individual contact with its information
class Contact
  attr_reader :details
  attr_accessor :full_name, :phone, :email, :address, :nick_name
  
  def initialize(details)
    @nick_name = titleize(details['nick_name'])
    @full_name = titleize(details['full_name'])
    @phone = details['phone']
    @email = details['email'].downcase
    @address = titleize(details['address'])
  end

  private

  def titleize(str)
    str.split.map(&:capitalize).join(' ')
  end
end