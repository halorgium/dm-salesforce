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
      @connection ||= Connection.new(@uri.user, @uri.password, @uri.host + @uri.path)
    end

    def read_many(query)
      ::DataMapper::Collection.new(query) do |set|
        read(query) do |result|
          set.load(result)
        end
      end
    end

    def read_one(query)
      read(query) do |result|
        return query.model.load(result, query)
      end
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

    def update(attributes, query)
      arr = if key_condition = query.conditions.find {|op,prop,val| prop.key?}
        [ make_salesforce_obj(query, attributes, key_condition.last) ]
      else
        read_many(query).map do |obj|
          obj = make_salesforce_obj(query, attributes, x.key)
        end
      end
      connection.update(arr).size
    rescue Connection::UpdateError => e
      populate_errors_for(e.records, arr, query)
      e.successful_records.size
    end

    def delete(query)
      keys = if key_condition = query.conditions.find {|op,prop,val| prop.key?}
        [key_condition.last]
      else
        query.repository.read_many(query).map {|r| r.key}
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
          else
            error.fields.each do |field|
              resource.add_salesforce_error_for(field, error.message)
            end
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

    private
    def read(query, &block)
      repository = query.repository
      properties = query.fields
      properties_with_indexes = Hash[*properties.zip((0...properties.size).to_a).flatten]
      conditions = query.conditions.map {|c| SQL.from_condition(c, repository)}.compact.join(") AND (")

      sql = "SELECT #{query.fields.map {|f| f.field(repository.name)}.join(", ")} from #{query.model.storage_name(repository.name)}"
      sql << " WHERE (#{conditions})" unless conditions.empty?
      sql << " ORDER BY #{SQL.order(query.order[0])}" unless query.order.empty?
      sql << " LIMIT #{query.limit}" if query.limit

      DataMapper.logger.debug sql

      result = connection.query(sql)

      return unless result.records

      result.records.each do |record|
        accum = []
        properties_with_indexes.each do |(property, idx)|
          meth = connection.field_name_for(property.model.storage_name(repository.name), property.field(repository.name))
          accum[idx] = normalize_id_value(query.model, property, record.send(meth))
        end
        yield accum
      end
    end

    def make_salesforce_obj(query, attrs, key)
      klass_name = query.model.storage_name(query.repository.name)
      values = {}
      if key
        key_value = query.conditions.find {|op,prop,val| prop.key?}.last
        values["id"] = normalize_id_value(query.model, query.model.properties[:id], key_value)
      end

      attrs.each do |property,value|
        normalized_value = normalize_id_value(query.model, property, value)
        values[property.field(query.repository.name)] = normalized_value
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
