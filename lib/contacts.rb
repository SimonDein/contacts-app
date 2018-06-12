=begin
When instatiating contacts -
 - each contact should be a Contact-object
 - each contact object should have a getters and setters for details
=end
class Contacts
  attr_reader :details
  
  def initialize(details)
    @details = details

  end
  
end