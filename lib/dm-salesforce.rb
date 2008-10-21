$:.push File.expand_path(File.dirname(__FILE__))
require "fileutils"

module SalesforceAPI
  class CreateError   < StandardError; end
  class ReadError     < StandardError; end
  class DeleteError   < StandardError; end
  class UpdateError   < StandardError; end
  class FieldNotFound < StandardError; end
end

module DataMapper
  module Adapters
    
    module SQL
      
      class << self
      
        def from_condition(condition, repository)
          op, prop, value = condition
          operator = case op
            when String then operator
            when :eql, :in then equality_operator(value)
            when :not      then inequality_operator(value)
            when :like     then "LIKE #{quote_value(value)}"
            when :gt       then "> #{quote_value(value)}"
            when :gte      then ">= #{quote_value(value)}"
            when :lt       then "< #{quote_value(value)}"
            when :lte      then "<= #{quote_value(value)}"
            else raise "CAN HAS CRASH?"
          end
          case prop
          when Property
            "#{prop.field} #{operator}"
          when Query::Path
            rels = prop.relationships
            names = rels.map {|r| storage_name(r, repository) }.join(".")
            "#{names}.#{prop.field} #{operator}"
          end
        end

        def storage_name(rel, repository)
          rel.parent_model.storage_name(repository.name)
        end
        
        def order(direction)
          "#{direction.property.field} #{direction.direction.to_s.upcase}"
        end
        
        private
        def equality_operator(value)
          case value
          when Array then "IN #{quote_value(value)}"
          else "= #{quote_value(value)}"
          end
        end
        
        def inequality_operator(value)
          case value
          when Array then "NOT IN #{quote_value(value)}"
          else "!= #{quote_value(value)}"
          end
        end
        
        def quote_value(value)
          case value
          when Array then "(#{value.map {|v| quote_value(v)}.join(", ")})"
          when NilClass then "NULL"
          when String then "'#{value.gsub(/'/, "\\'").gsub(/\\/, %{\\\\})}'"
          else "#{value}"
          end
        end        
      end
      
    end
    
    class SalesforceAdapter < AbstractAdapter
      
      def initialize(name, uri_or_options)
        super
        
        generate_soap_classes
        
        @resource_naming_convention = proc do |value|
          klass = Extlib::Inflection.constantize(value)
          if klass.respond_to?(:salesforce_class)
            klass.salesforce_class
          else
            value.split("::").last
          end
        end
        @field_naming_convention = proc do |value|
          klass = SalesforceAPI.const_get(value.model.storage_name(name))
          column = value.name.to_s
          fields = [column, column.camel_case, "#{column}__c".downcase]
          options = /^(#{fields.join("|")})$/i
          matches = klass.instance_methods(false).grep(options)
          if matches.any?
            matches.first
          else
            raise SalesforceAPI::FieldNotFound, 
              "You specified #{column} as a field, but neither #{fields.join(" or ")} exist. " \
              "Either manually specify the field name with :field, or check to make sure you have " \
              "provided a correct field name."
          end
        end
      end
      
      def generate_soap_classes
        if !@uri.host.empty? && !@uri.path.empty?
          path = File.join(Dir.pwd, @uri.host, @uri.path)
        elsif !@uri.host.empty?
          path = File.join(Dir.pwd, @uri.host)
        else
          path = @uri.path
        end

        basename = File.basename(path)

        # Generate Ruby files and move them into .salesforce for future use
        unless File.directory?("#{ENV["HOME"]}/.salesforce/#{basename}") &&
          Dir["#{ENV["HOME"]}/.salesforce/#{basename}/SalesforceAPI*.rb"].size == 3
            old_args = ARGV.dup
            path = path =~ %r{^/} ? path : File.expand_path(path)
            if !File.file?(path)
              raise Errno::ENOENT, "No such file or directory - #{path}"
            end
            ARGV.replace %W(--wsdl #{path} --module_path SalesforceAPI --classdef SalesforceAPI --type client)
            load `which wsdl2ruby.rb`.chomp
            FileUtils.mkdir_p "#{ENV["HOME"]}/.salesforce/#{basename}"
            FileUtils.mv Dir["SalesforceAPI*"], "#{ENV["HOME"]}/.salesforce/#{basename}/"
            FileUtils.rm Dir["SforceServiceClient.rb"]
        end
        
        require "salesforce_api"
        $:.push "#{ENV["HOME"]}/.salesforce/#{basename}"
        require "SalesforceAPIDriver"
      end
      
      def connect!
        SalesforceAPI::Connection.new(URI.unescape(@uri.user), @uri.password).driver
      end
      
      def connection
        @connection ||= connect!
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
      
      private
      def read(query, &block)
        repository = query.repository
        properties = query.fields
        properties_with_indexes = Hash[*properties.zip((0...properties.size).to_a).flatten]
        conditions = query.conditions.map {|c| SQL.from_condition(c, repository)}.compact.join(") AND (")
      
        query_string = "SELECT #{query.fields.map {|f| f.field(repository.name)}.join(", ")} from #{query.model.storage_name(repository.name)}"
        query_string << " WHERE (#{conditions})" unless conditions.empty?
        query_string << " ORDER BY #{SQL.order(query.order[0])}" unless query.order.empty?
        query_string << " LIMIT #{query.limit}" if query.limit

        DataMapper.logger.debug query_string
      
        begin
          results = connection.query(:queryString => query_string).result
        rescue SOAP::FaultError => e
          raise SalesforceAPI::ReadError, e.message
        end

        return unless results.records
        
        # This is the core logic that handles the difference between all/first
        (results.records || []).each do |result|
          yield props_from_result(properties_with_indexes, result, repository)
        end
      end
      
      def props_from_result(properties_with_indexes, result, repo)
        properties_with_indexes.inject([]) do |accum, (prop, idx)|
          meth = soap_attr(prop, repo, result.class)
          accum[idx] = result.send(meth)
          accum
        end
      end
      
      public
      def update(attributes, query)
        arr = if key_condition = query.conditions.find {|op,prop,val| prop.key?}
          [ make_sforce_obj(query, attributes, key_condition.last) ]
        else
          read_many(query).map do |obj|
            obj = make_salesforce_obj(query, attributes, x.key)
          end
        end
        results = connection.update(arr)
        results.select {|r| r.success == true}.size
      end
      
      def create(resources)
        map = {}
        arr = resources.map do |resource|
          obj = make_sforce_obj(resource, resource.dirty_attributes, nil)
        end
        
        connection.create(arr).each_with_index do |result, i|
          if result.success
            resource = resources[i]
            key = resource.class.key(repository.name).first
            resource.instance_variable_set(key.instance_variable_name, result.id)
          else
            raise SalesforceAPI::CreateError, 
              results.errors.map {|e| "#{e.statusCode}: #{e.message}"}.join(", ")
          end
        end.size
        
      end
      
      def delete(query)
        keys = if key_condition = query.conditions.find {|op,prop,val| prop.key?}
          [key_condition.last]
        else
          query.read_many.map {|r| r.key}
        end
        
        results = connection.delete(keys)
        
        if results.all? {|r| r.success}
          results.size
        else
          raise SalesforceAPI::DeleteError, 
            results.find {|r| r.success == false}.errors.map {|e| "#{e.statusCode}: #{e.message}"}.join(", ")
        end
      end
      
      # A dummy method to allow migrations without upsetting any data
      def destroy_model_storage(*args)
        true
      end
      
      # A dummy method to allow migrations without upsetting any data
      def create_model_storage(*args)
        true
      end
      
      
      private
      def make_sforce_obj(query, attrs, key = nil)
        klass = SalesforceAPI.const_get(query.model.storage_name(query.repository.name))
        obj = klass.new
        obj.id = query.conditions.find {|op,prop,val| prop.key?}.last if key
        attrs.each do |prop,val|
          obj.send("#{soap_attr(prop, query.repository, obj.class)}=", val)
        end
        obj
      end
      
      def soap_attr(prop, repository, klass)
        meth = klass.instance_methods.
          grep(/^#{prop.field(repository.name)}$/i)
        meth && !meth.empty? ? meth[0] : meth
      end
      
    end
    
  end
end
