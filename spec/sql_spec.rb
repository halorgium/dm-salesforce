describe DataMapper::Salesforce::SQL do
  describe "Operator" do
    let(:account) { Account.gen(:number_of_employees => 10) }
    let(:query) { Account.all(:id => account.id) }

    it 'implements :gt' do
      query.first(:number_of_employees.gt => 5).should_not be_nil
    end

    it 'implements :gte' do
      query.first(:number_of_employees.gte => 10).should_not be_nil
    end

    it 'implements :lt' do
      query.first(:number_of_employees.lt => 15).should_not be_nil
    end

    it 'implements :lte' do
      query.first(:number_of_employees.lte => 10).should_not be_nil
    end

    it 'scopes contacts to account' do
      contacts = 5.of { Contact.gen(:account => account) }
      account.reload.contacts.should == contacts
    end
  end
end
