module DataMapper::SalesForce
  module Types
    class Serial < Type
      primitive ::String
      min 15
      max 15
      serial true

      def self.dump(value, property)
        value[0..14] unless value.blank?
      end
    end
  end
end
