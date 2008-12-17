module DataMapperSalesforce
  module SalesforceExtensions
    def self.included(mod)
      mod.extend(ClassMethods)
    end

    module ClassMethods
      def properties_with_salesforce_validation
        @properties_with_salesforce_validation ||= []
      end

      def add_salesforce_validation_for(property)
        unless properties_with_salesforce_validation.include?(property)
          validates_with_block property.name do
            if message = salesforce_errors[property]
              [false, message]
            else
              true
            end
          end
        end
        properties_with_salesforce_validation << property
      end
    end

    def add_salesforce_error_for(field, message)
      if property = property_for_salesforce_field(field)
        self.class.add_salesforce_validation_for(property)
        salesforce_errors[property] = message
      else
        raise "Field not found"
      end
    end

    def property_for_salesforce_field(name)
      self.class.properties.find do |p|
        p.field.downcase == name.downcase
      end
    end

    def salesforce_errors
      @salesforce_errors ||= {}
    end
  end
end
