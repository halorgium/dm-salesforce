class Account
  include DataMapper::Resource

  property :id, String, :serial => true
  property :name, String
end

describe "Account" do
  it "return the first element" do
    Account.first.should_not be_nil
  end
end
