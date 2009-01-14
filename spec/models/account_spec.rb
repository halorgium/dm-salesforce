class Account
  include DataMapper::Resource
  
  def self.default_repository_name
    :salesforce
  end

  def self.salesforce_id_properties
    :id
  end

  property :id, String, :serial => true
  property :name, String
end

describe "Account" do
  it "return the first element" do
    Account.first.should_not be_nil
  end

  it "has a 15 character long id" do
    Account.first.id.size.should == 15
  end
end
