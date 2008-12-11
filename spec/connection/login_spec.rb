module DataMapperSalesforce
  describe "Using the raw connection" do
    describe "when authenticating without an organization id" do
      describe "with the correct credentials" do
        it "succeeds" do
          db = DataMapper.repository.adapter.connection
          Connection.new(VALID_USER.username, VALID_USER.password, db.wsdl_path)
        end
      end

      describe "with an invalid password" do
        it "fails to login" do
          db = DataMapper.repository.adapter.connection
          lambda { Connection.new(VALID_USER.username, 'bad-password', db.wsdl_path) }.
            should raise_error(Connection::LoginFailed)
        end
      end
    end

    describe "when authenticating with an organization id" do
      describe "with the correct credentials" do
        it "succeeds" do
          db = DataMapper.repository.adapter.connection
          Connection.new(VALID_SELF_SERVICE_USER.username, VALID_SELF_SERVICE_USER.password, db.wsdl_path, db.organization_id)
        end
      end

      describe "with an invalid password" do
        it "fails to login" do
          db = DataMapper.repository.adapter.connection
          lambda { Connection.new(VALID_SELF_SERVICE_USER.username, "bad-password", db.wsdl_path, db.organization_id) }.
            should raise_error(Connection::LoginFailed)
        end
      end
    end
  end
end
