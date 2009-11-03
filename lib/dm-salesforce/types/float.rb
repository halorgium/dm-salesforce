module DataMapper::SalesForce
  module Types
    class Float < Type
      primitive ::Float
      default 0.0

      def self.load(value, property)
        value || default
      end
    end
  end
end
