class Account
  include DataMapper::Resource
  
  def self.default_repository_name
    :salesforce
  end

  property :id, String, :serial => true
  property :name, String
end

describe "Account" do
  it "return the first element" do
    Account.first.should_not be_nil
  end
end
