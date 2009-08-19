describe "Finding a Contact" do
  it "return the first element" do
    Contact.first.should_not be_nil
  end

  it "has a 15 character long id" do
    Contact.first.id.size.should == 15
  end

  it "has a 15 character long account_id" do
    contact = Contact.create(
      :first_name => 'Per',
      :last_name => 'Son',
      :email => "person@example.com",
      :account => Account.create(:name => "Puma Shoes Unlimited")
    )
    contact.account_id.size.should == 15
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

  describe "when a unique property" do
    it "is invalid" do
      pending
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
      c.update(:email => 'person')
      c.should_not be_valid
      c.errors.size.should == 1
      c.errors.on(:email).should == ["Email: invalid email address: person"]
    end
  end

  describe "when a unique property" do
    it "is invalid" do
      pending
      c = Contact.create(:first_name => 'Per', :last_name => 'Son', :email => "person@company.com")
      c.update(:irc_nick => 'qblake_')
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
      c.update(:last_name => "")
      c.should_not be_valid
      c.errors.size.should == 1
      c.errors.on(:last_name).should == ["Required fields are missing: [LastName]"]
    end
  end

  describe "when an account is specified" do
    it "correctly connects the account when its relationship object is specified" do
      a = Account.create(:name => "Puma Shoes Unlimited")
      c = Contact.create(:first_name => 'Per', :last_name => 'Son', :email => "person@company.com", :account => a)
      c.reload.account.should == a
    end

    it "correctly connects the account when its foreign key is specified" do
      a = Account.create(:name => "Puma Shoes Unlimited")
      c = Contact.create(:first_name => 'Per', :last_name => 'Son', :email => "person@company.com", :account_id => a.id)
      c.reload.account.should == a
    end
  end

  describe "when updating a boolean field to false" do
    it "should update" do
      pending
    end
  end
end

