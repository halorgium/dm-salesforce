module DataMapperSalesforce
  describe "Running auto_migrate!" do
    it "should not raise errors" do
      lambda { DataMapper.auto_migrate! }.should_not raise_error
    end
  end
  describe "Running auto_upgrade!" do
    it "should not raise errors" do
      lambda { DataMapper.auto_upgrade! }.should_not raise_error
    end
  end
end
