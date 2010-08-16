module DataMapper::Salesforce
  module Property
    class Boolean < ::DataMapper::Property::Integer
      FALSE = 0
      TRUE  = 1

      def self.dump(value, property)
        case value
        when nil, false then FALSE
        else TRUE
        end
      end

      def self.load(value, property)
        [true, 1, '1', 'true', 'TRUE', TRUE].include?(value)
      end
    end
  end
end
