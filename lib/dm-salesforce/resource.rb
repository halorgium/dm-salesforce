module DataMapper
  module SalesForce
    module Resource
      def self.included(model)
        model.send :include, DataMapper::Resource
        model.send :include, DataMapper::SalesForce::Types
      end
    end
  end
end
