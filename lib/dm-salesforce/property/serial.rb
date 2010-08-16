module DataMapper::Salesforce
  module Property
    class Serial < ::DataMapper::Property::String
      accept_options :serial
      serial true

      length 15

      def self.dump(value, property)
        value[0..14] unless value.blank?
      end
    end
  end
end
