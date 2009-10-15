module DataMapperSalesforce
  class Adapter < DataMapper::Adapters::AbstractAdapter
    include SQL

    def initialize(name, uri_or_options)
      super
      @resource_naming_convention = proc do |value|
        klass = Extlib::Inflection.constantize(value)
        if klass.respond_to?(:salesforce_class)
          klass.salesforce_class
        else
          value.split("::").last
        end
      end
      @field_naming_convention = proc do |property|
        connection.field_name_for(property.model.storage_name(name), property.name.to_s)
      end
    end

    def connection
      @connection ||= Connection.new(options["username"], options["password"], options["path"], options["apidir"])
    end

    def create(resources)
      arr = resources.map do |resource|
        make_salesforce_obj(resource, resource.dirty_attributes)
      end

      result = connection.create(arr)
      result.each_with_index do |record, i|
        resource = resources[i]
        id_field = resource.class.key(resource.repository.name).find {|p| p.serial?}
        if id_field
          normalized_value = normalize_id_value(resource.class, id_field, record.id)
          id_field.set!(resource, normalized_value)
        end
      end
      result.size
    rescue Connection::CreateError => e
      populate_errors_for(e.records, resources)
      e.successful_records.size
    end

    def update(attributes, collection)
      query = collection.query

      arr = if key_condition = query.conditions.find { |c| c.subject.key? }
        [ make_salesforce_obj(query, attributes, key_condition) ]
      else
        # FIXME: this ain't right
        execute_query(query).map do |obj|
          obj = make_salesforce_obj(query, attributes, obj.key)
        end
      end

      connection.update(arr).size

    rescue Connection::UpdateError => e
      populate_errors_for(e.records, arr, query)
      e.successful_records.size
    end

    def delete(collection)
      query = collection.query

      keys = if key_condition = query.conditions.find { |c| c.subject.key? }
        [key_condition.value]
      else
        # FIXME: this ain't right
        execute_query(query).map { |r| r.key }
      end

      connection.delete(keys).size
    end

    def populate_errors_for(records, resources, query = nil)
      records.each_with_index do |record,i|
        next if record.success

        if resources[i].is_a?(DataMapper::Resource)
          resource = resources[i]
        elsif resources[i].is_a?(SalesforceAPI::SObject)
          resource = query.repository.identity_map(query.model)[[resources[i].id]]
        else
          resource = query.repository.identity_map(query.model)[[resources[i]]]
        end

        resource.class.send(:include, SalesforceExtensions)
        record.errors.each do |error|
          case error.statusCode
          when "DUPLICATE_VALUE"
            if error.message =~ /duplicate value found: (.*) duplicates/
              resource.add_salesforce_error_for($1, error.message)
            end
          when "REQUIRED_FIELD_MISSING", "INVALID_EMAIL_ADDRESS"
            error.fields.each do |field|
              resource.add_salesforce_error_for(field, error.message)
            end
          when "SERVER_UNAVAILABLE"
            raise Connection::ServerUnavailable, "The salesforce server is currently unavailable"
          else
            raise Connection::UnknownStatusCode, "Got an unknown statusCode: #{error.statusCode.inspect}"
          end
        end
      end
    end

    # A dummy method to allow migrations without upsetting any data
    def destroy_model_storage(*args)
      true
    end

    # A dummy method to allow auto_migrate! to run
    def upgrade_model_storage(*args)
      true
    end

    # A dummy method to allow migrations without upsetting any data
    def create_model_storage(*args)
      true
    end

    # Reading responses back from SELECTS:
    #   In the typical case, response.size reflects the # of records returned.
    #   In the aggregation case, response.size reflects the count.
    #
    # Interpretation of this field requires knowledge of whether we
    # are expecting an aggregate result, thus the response is
    # processed differently depending on invocation.
    def read(query)
      properties = query.fields
      repository = query.repository

      response = execute_query(query)
      return [] unless response.records

      rows = response.records.inject([]) do |results, record|
        results << properties.inject({}) do |result, property|
          meth = connection.field_name_for(property.model.storage_name(repository.name), property.field)
          result[property] = normalize_id_value(query.model, property, record.send(meth))
          result
        end
      end

      query.model.load(rows, query)
    end

    # SOQL doesn't support anything but count(), so we catch it here
    # and interpret the result.
    def aggregate(query)
      query.fields.each do |f|
        unless f.target == :all && f.operator == :count
          raise ArgumentError, %{Aggregate function #{f.operator} not supported in SOQL}
        end
      end

      [ execute_query(query).size ]
    end

    private
    def execute_query(query)
      repository = query.repository
      conditions = query.conditions.map {|c| from_condition(c, repository)}.compact.join(") AND (")

      fields = query.fields.map do |f|
        case f
          when DataMapper::Property
            f.field
          when DataMapper::Query::Operator
            %{#{f.operator}()}
          else
            raise ArgumentError, "Unknown query field #{f.class}: #{f.inspect}"
        end
      end.join(", ")

      sql = "SELECT #{fields} from #{query.model.storage_name(repository.name)}"
      sql << " WHERE (#{conditions})" unless conditions.empty?
      sql << " ORDER BY #{order(query.order[0])}" unless query.order.empty?
      sql << " LIMIT #{query.limit}" if query.limit

      DataMapper.logger.debug sql if DataMapper.logger

      connection.query(sql)
    end

    def make_salesforce_obj(query, attrs, key = nil)
      klass_name = query.model.storage_name(query.repository.name)
      values = {}

      if key
        key_value = query.conditions.find { |c| c.subject.key? }.value
        values["id"] = normalize_id_value(query.model, query.model.properties[:id], key_value)
      end

      attrs.each do |property, value|
        next if property.serial? and value.nil?
        normalized_value = normalize_id_value(query.model, property, value)
        values[property.field] = normalized_value
      end

      connection.make_object(klass_name, values)
    end

    # This could be cheaper.
    def normalize_id_value(klass, property, value)
      return value unless value
      if klass.respond_to?(:salesforce_id_properties)
        properties = Array(klass.salesforce_id_properties).map {|p| p.to_sym}
        return value[0..14] if properties.include?(property.name)
      end
      value
    end
  end
end
