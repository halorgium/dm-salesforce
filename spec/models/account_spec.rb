describe "Account" do
  it "return the first element" do
    Account.first.should_not be_nil
  end

  it "has a 15 character long id" do
    Account.first.id.size.should == 15
  end

  it "has a 15 character long id" do
    Account.create(:name => "Adidas Corporation").id.size.should == 15
  end
end
