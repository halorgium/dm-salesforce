module DataMapper::Salesforce
  module Types
    class Integer < Type
      primitive ::Integer
      default 0

      def self.load(value, property)
        Integer(value)
      end
    end
  end
end
