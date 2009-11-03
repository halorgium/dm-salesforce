module DataMapper::Salesforce
  module Resource
    def self.included(model)
      model.send :include, DataMapper::Resource
      model.send :include, DataMapper::Salesforce::Types
    end
  end
end
