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
      Collection.new(query) do |set|
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
        key = resource.class.key(repository.name).first
        resource.instance_variable_set(key.instance_variable_name, record.id)
      end
      result.size
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
    end

    def delete(query)
      keys = if key_condition = query.conditions.find {|op,prop,val| prop.key?}
        [key_condition.last]
      else
        query.read_many.map {|r| r.key}
      end

      connection.delete(keys).size
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
          accum[idx] = record.send(meth)
        end
        yield accum
      end
    end

    def make_salesforce_obj(query, attrs, key)
      klass_name = query.model.storage_name(query.repository.name)
      values = {}
      values["id"] = query.conditions.find {|op,prop,val| prop.key?}.last if key
      attrs.each do |property,value|
        values[property.field(query.repository.name)] = value
      end
      connection.make_object(klass_name, values)
    end
  end
end
