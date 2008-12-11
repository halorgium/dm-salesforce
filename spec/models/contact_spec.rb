class Contact
  include DataMapper::Resource

  property :id,    String, :serial => true
  property :email, String
end

describe "Contact" do
  it "return the first element" do
    Contact.first.should_not be_nil
  end
end
