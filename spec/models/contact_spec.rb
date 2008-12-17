class Contact
  include DataMapper::Resource
  
  def self.default_repository_name
    :salesforce
  end

  property :first_name, String
  property :last_name, String
  property :email, String
  property :irc_nick, String
  
  repository(:salesforce) do
    property :id,    String, :serial => true
  end
end

describe "Finding a Contact" do
  it "return the first element" do
    Contact.first.should_not be_nil
  end
  
  it "should get a list of contacts" do
    Contact.all.should_not be_empty
  end
  
  it "should get a single contact" do
    contact = Contact.all.first
    Contact.get(contact.id).should == contact
  end
end

describe "Creating a Contact" do
  describe "when the email address is invalid" do
    it "is invalid" do
      c = Contact.create(:first_name => 'Per', :last_name => 'Son', :email => "person")
      c.should_not be_valid
      c.errors.size.should == 1
      c.errors.on(:email).should == ["Email: invalid email address: person"]
    end
  end

  describe "when the irc_nick is invalid" do
    it "is invalid" do
      c = Contact.create(:first_name => 'Per', :last_name => 'Son', :email => "person@company.com", :irc_nick => 'qblake_')
      c.should_not be_valid
      c.errors.size.should == 1
      errors = c.errors.on(:irc_nick)
      errors.size.should == 1
      errors.first.should =~ /duplicate value found: IRC_Nick__c duplicates value on record with id/
    end
  end

  describe "when the last name is missing" do
    it "is invalid" do
      c = Contact.create(:first_name => 'Per', :email => "person@company.com")
      c.should_not be_valid
      c.errors.size.should == 1
      c.errors.on(:last_name).should == ["Required fields are missing: [LastName]"]
    end
  end
end

describe "Updating a Contact" do
  describe "when the email address is invalid" do
    it "is invalid" do
      c = Contact.create(:first_name => 'Per', :last_name => 'Son', :email => "person@company.com")
      c.update_attributes(:email => 'person')
      c.should_not be_valid
      c.errors.size.should == 1
      c.errors.on(:email).should == ["Email: invalid email address: person"]
    end
  end

  describe "when the irc_nick is invalid" do
    it "is invalid" do
      c = Contact.create(:first_name => 'Per', :last_name => 'Son', :email => "person@company.com")
      c.update_attributes(:irc_nick => 'qblake_')
      c.should_not be_valid
      c.errors.size.should == 1
      errors = c.errors.on(:irc_nick)
      errors.size.should == 1
      errors.first.should =~ /duplicate value found: IRC_Nick__c duplicates value on record with id/
    end
  end

  describe "when the last name is missing" do
    it "is invalid" do
      c = Contact.create(:first_name => 'Per', :last_name => 'Son', :email => "person@company.com")
      c.update_attributes(:last_name => "")
      c.should_not be_valid
      c.errors.size.should == 1
      c.errors.on(:last_name).should == ["Required fields are missing: [LastName]"]
    end
  end
end

