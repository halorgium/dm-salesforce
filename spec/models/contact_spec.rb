describe "Finding a Contact" do
  let(:valid_id) { DataMapper.repository(:salesforce) { Contact.gen.id } }

  it "return the first element" do
    Contact.first(:id => valid_id).should_not be_nil
  end

  it "has a 15 character long id" do
    #pending "testing serial types should be done elsewhere"
    Contact.first(:id => valid_id).id.size.should == 15
  end

  it "has a 15 character long account_id" do
    #pending "testing association ids as serial types should be done elsewhere"
    Contact.first(:id => valid_id).account_id.size.should == 15
  end

  it "should get a single contact" do
    Contact.get(valid_id).should_not be_nil
    Contact.get(valid_id).should be_valid
  end
end

describe "Creating a Contact" do

  describe "specifying an account to associate with" do
    let(:account) { Account.gen }
    describe "using the object" do
      it 'is valid' do
        contact = Contact.create(:first_name => 'Per', :last_name => 'Son', :email => "person@company.com", :account => account)
        contact.should be_valid
        contact.account.should eql(account)
      end
    end
    describe "using the id" do
      it 'is valid' do
        contact = Contact.create(:first_name => 'Per', :last_name => 'Son', :email => "person@company.com", :account_id => account.id)
        contact.should be_valid
        contact.account.should eql(account)
      end
    end
  end

  describe "when the email address is invalid" do
    it "is invalid" do
      contact = Contact.gen(:email => "person")
      contact.should_not be_valid
      contact.errors.should have_key(:email)
    end
  end

  describe "when a unique property" do
    before(:each) do
      Contact.all(:irc_nick => 'c00ldud3').destroy
    end

    it "is invalid" do
      contact  = Contact.gen(:irc_nick => 'c00ldud3')
      contact.should be_valid

      duplicate_irc_nick = Contact.gen(:irc_nick => 'c00ldud3')
      duplicate_irc_nick.should_not be_valid
    end
  end

  describe "when the last name is missing" do
    it "is invalid" do
      contact = Contact.create(:first_name => 'Per', :email => "person@company.com")
      contact.should_not be_valid
      contact.errors.should have_key(:last_name)
    end
  end
end

describe "Allocating a Contact" do
  describe "when the last name is missing" do
    it "has validation errors" do
      c = Contact.make(:last_name => nil)
      c.should_not be_valid
      c.errors.should have_key(:last_name)
    end
  end
end

describe "Updating a Contact" do
  describe "when the email address is invalid" do
    it "is invalid" do
      c = Contact.create(:first_name => 'Per', :last_name => 'Son', :email => "person@company.com")
      c.update(:email => 'person')
      c.should_not be_valid
      c.errors.should have_key(:email)
    end
  end

  describe "when a unique property" do
    before(:each) do
      Contact.all(:irc_nick.like => 'c00ldud%').destroy
    end
    it "is invalid" do
      #pending "test duplicates on update elsewhere"
      contact = Contact.gen(:irc_nick => 'c00ldud3')
      contact.should be_valid

      conflicting_contact_after_update = Contact.gen(:irc_nick => 'c00ldud4')
      conflicting_contact_after_update.should be_valid

      lambda do
        contact.update(:irc_nick => 'c00ldud5')
      end.should_not change { contact.valid? }
      lambda do
        conflicting_contact_after_update.update(:irc_nick => 'c00ldud5')
      end.should change { conflicting_contact_after_update.valid? }
    end
  end

  describe "when the last name is missing" do
    it "is invalid" do
      contact = Contact.create(:first_name => 'Per', :last_name => 'Son', :email => "person@company.com")
      contact.update(:last_name => "")
      contact.should_not be_valid
      contact.errors.should have_key(:last_name)
    end
  end

  describe "when updating a boolean field to false" do
    before(:each) do
      Contact.all(:first_name => 'OptOutEr').destroy
    end
    it "should update" do
      contact = Contact.gen(:first_name => 'OptOutEr', :has_opted_out_of_email => true)
      lambda { contact.update(:has_opted_out_of_email => false) }.
        should change { DataMapper.repository(:salesforce) { Contact.get(contact.id).has_opted_out_of_email } }
    end
  end
end
