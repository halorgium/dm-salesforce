module DataMapper::SalesForce
  module Types
    class Boolean < Type
      primitive ::String
      default false

      def self.dump(value, property)
        value.nil? ? '0' : value
      end

      def self.load(value, property)
        case value
        when TrueClass  then value
        when String     then value == '1' || value == 'true'
        end
      end
    end
  end
end
