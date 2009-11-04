describe DataMapper::Salesforce::Types::Boolean do
  let(:active_account) { DataMapper.repository(:salesforce) { Account.gen(:active => true) } }
  let(:inactive_account) { DataMapper.repository(:salesforce) { Account.gen(:active => false) } }
  describe 'dumps and loads' do
    it 'true' do
      Account.first(:id => active_account.id).active.should == true
    end

    it 'false' do
      Account.first(:id => inactive_account.id).active.should == false
    end
  end
end
