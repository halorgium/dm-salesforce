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

  it "should find a single account" do
    account = Account.create(:name => "Adidas Corporation")
    Account.first(:name => "Adidas Corporation").name.should == account.name
  end

  it "should find multiple accounts" do
    Account.create(:name => "Adidas Corporation")
    Account.all(:name => "Adidas Corporation").map do |account|
      account.name.should == "Adidas Corporation"
    end
  end

  it "should delete an account" do
    Account.all(:name => "Topfunky Corporation").each {|a| a.destroy }
    Account.create(:name => "Topfunky Corporation").destroy
    Account.first(:name => "Topfunky Corporation").should be_nil
  end
end
