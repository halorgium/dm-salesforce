module DataMapper::Salesforce
  module Resource
    def self.included(model)
      model.send :include, DataMapper::Resource
      model.send :include, case DataMapper::VERSION
                           when /^0\.10/ then DataMapper::Salesforce::Types
                           when /^1\.0/  then DataMapper::Salesforce::Property
                           else raise "DataMapper #{DataMapper::VERSION} is an unsupported version"
                           end
    end
  end
end
