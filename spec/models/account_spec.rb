describe "Account" do
  describe "#first" do
    #pending "testing first should not be on account"
    it "return the first element" do
      Account.first.should_not be_nil
    end
    it "has a 15 character long id" do
      Account.first.id.size.should == 15
    end
  end

  describe ".get" do
    let(:account_id) { DataMapper.repository(:salesforce) { Account.create(:name => "Adidas Corp").id } }

    it "with a valid id is successfull" do
      Account.get(account_id).should be_valid
    end
  end

  describe "#create" do
    it "has errors when omitting the account name" do
      a = Account.create(:active => false)
      a.errors.should have_key(:name)
    end
    describe "successful creation" do
      let(:account) { Account.create(:name => "Adidas Corporation") }
      it "has a 15 character long id" do
        account.id.size.should == 15
      end
      it 'is not active by default' do
        account.active.should_not be_true
      end

      it 'floats can be nil' do
        account.annual_revenue = nil
        account.should be_valid
        account.annual_revenue.should be_nil
      end
    end
    describe "successful creation with on-offs" do
      let(:account) { Account.create(:name => "Adidas Corporation", :active => true, :annual_revenue => 4000.25) }
      it 'is active' do
        account.active.should be_true
      end
      it 'has 4000.25 in annual revenue' do
        account.annual_revenue.should eql(4000.25)
      end
    end
  end
end
