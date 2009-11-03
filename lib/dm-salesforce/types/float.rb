module DataMapper::Salesforce
  module Types
    class Float < Type
      primitive ::Float
      default 0.0
    end
  end
end
