module DataMapperSalesforce
  class Adapter < DataMapper::Adapters::AbstractAdapter
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

    def normalize_uri(uri_or_options)
      if uri_or_options.kind_of?(Addressable::URI)
        return uri_or_options
      end

      if uri_or_options.kind_of?(String)
        uri_or_options = Addressable::URI.parse(uri_or_options)
      end

      adapter  = uri_or_options.delete(:adapter).to_s
      user     = uri_or_options.delete(:username)
      password = uri_or_options.delete(:password)
      host     = uri_or_options.delete(:host) || "."
      path     = uri_or_options.delete(:path)
      query    = uri_or_options.to_a.map { |pair| pair * '=' } * '&'
      query    = nil if query == ''

      return Addressable::URI.new({:adapter => adapter, :user => user, :password => password, :host => host, :path => path, :query => query})
    end

    def connection
      @connection ||= Connection.new(@options[:username], @options[:password], @options[:host] + @options[:path])
    end

    def create(resources)
      arr = resources.map do |resource|
        obj = make_salesforce_obj(resource, resource.dirty_attributes, nil)
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
      arr = if key_condition = query.conditions.find {|op| op.subject.key? }
        [ make_salesforce_obj(query, attributes, key_condition) ]
      else
        read_many(query).map do |obj|
          obj = make_salesforce_obj(query, attributes, x.key)
        end
      end
      connection.update(arr).size
    rescue Connection::UpdateError => e
      populate_errors_for(e.records, arr, collection)
      e.successful_records.size
    end

    def delete(collection)
      query = collection.query
      keys = if key_condition = query.conditions.find {|op| op.subject.key?}
        [key_condition.value]
      else
        query.read_many.map {|r| r.key}
      end

      connection.delete(keys).size
    end

    def populate_errors_for(records, resources, collection = nil)
      records.each_with_index do |record,i|
        next if record.success

        if resources[i].is_a?(DataMapper::Resource)
          resource = resources[i]
        elsif resources[i].is_a?(SalesforceAPI::SObject)
          resource = collection.detect {|o| o.id == resources[i].id}
        else
          resource = collection.detect {|o| o.id == resources[i]}
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

    def read(query)
      repository = query.repository
      properties = query.fields
      properties_with_indexes = Hash[*properties.zip((0...properties.size).to_a).flatten]
      conditions = query.conditions.map {|c| SQL.from_condition(c, repository)}.compact.join(") AND (")

      sql = "SELECT #{query.fields.map {|f| f.field}.join(", ")} from #{query.model.storage_name(repository.name)}"
      sql << " WHERE (#{conditions})" unless conditions.empty?
      sql << " ORDER BY #{SQL.order(query.order[0])}" unless query.order.empty?
      sql << " LIMIT #{query.limit}" if query.limit

      DataMapper.logger.debug sql

      result = connection.query(sql)

      return [] unless result.records


      accum = []
      result.records.each do |record|
        hash = {}

        properties_with_indexes.each do |(property, idx)|
          meth = connection.field_name_for(property.model.storage_name(repository.name), property.field)
          hash[meth] = normalize_id_value(query.model, property, record.send(meth))
        end

        accum << hash
      end
      accum
    end

    private
    
    def make_salesforce_obj(query, attrs, key)
      klass_name = query.model.storage_name(query.repository.name)
      values = {}
      if key
        key_condition = query.conditions.find {|op| op.subject.key?}
        values["id"] = normalize_id_value(query.model, query.model.properties[:id], key_condition.value)
      end

      attrs.each do |property,value|
        unless value.nil?
          normalized_value = normalize_id_value(query.model, property, value)
          values[property.field] = normalized_value
        end
      end
      connection.make_object(klass_name, values)
    end

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
