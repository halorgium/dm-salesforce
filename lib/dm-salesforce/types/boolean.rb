module DataMapper::Salesforce
  module Types
    class Boolean < Type
      primitive String
      default false

      def self.dump(value, property)
        case value
        when nil, false then '0'
        else value
        end
      end

      def self.load(value, property)
        case value
        when TrueClass    then value
        when '1', 'true'  then true
        else false
        end
      end
    end
  end
end
