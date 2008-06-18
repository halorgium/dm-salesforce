$:.push File.expand_path(File.dirname(__FILE__))
require "fileutils"

module SalesforceAPI
  class CreateError < StandardError; end
  class ReadError   < StandardError; end
  class DeleteError < StandardError; end
  class UpdateError < StandardError; end
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
            names = prop.relationships.map {|r| r.parent_model.storage_name(repository.name)}.join(".")
            names << ".#{prop.field}"
            "#{names} #{operator}"
          end
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
        @resource_naming_convention = proc {|value| value.split("::").last}
        @field_naming_convention = proc {|value| Extlib::Inflection.camelize(value)}
        connect!
      end
      
      def connect!
        if !@uri.host.empty? && !@uri.path.empty?
          path = File.join(Dir.pwd, @uri.host, @uri.path)
        elsif !@uri.host.empty?
          path = File.join(Dir.pwd, @uri.host)
        else
          path = @uri.path
        end

        basename = File.basename(path)

        # Generate Ruby files and move them into .salesforce for future use
        unless File.directory? "#{ENV["HOME"]}/.salesforce/#{basename}"
          old_args = ARGV.dup
          path = path =~ %r{^/} ? path : File.expand_path(path)
          ARGV.replace %W(--wsdl #{path} --module_path SalesforceAPI --classdef SalesforceAPI --type client)
          p ARGV
          load `which wsdl2ruby.rb`.chomp
          FileUtils.mkdir_p "#{ENV["HOME"]}/.salesforce/#{basename}"
          FileUtils.mv Dir["SalesforceAPI*"], "#{ENV["HOME"]}/.salesforce/#{basename}/"
          FileUtils.rm Dir["SforceServiceClient.rb"]
        end
        
        require "salesforce_api"
        @connection = SalesforceAPI::Connection.new(URI.unescape(@uri.user), @uri.password, "#{ENV["HOME"]}/.salesforce/#{basename}").driver
      end
            
      def read_many(query)
        Collection.new(query) do |set|
          read(query, set, true)
        end
      end
      
      def read_one(query)
        read(query, query.model, false)
      end
      
      private
      def read(query, set, arr = true)
        repository = query.repository
        properties = query.fields
        properties_with_indexes = Hash[*properties.zip((0...properties.size).to_a).flatten]

        conditions = query.conditions.map {|c| SQL.from_condition(c, repository)}.compact.join(") AND (")
      
        query_string = "SELECT #{query.fields.map {|f| f.field}.join(", ")} from #{query.model.storage_name(repository.name)}"
        query_string << " WHERE (#{conditions})" unless conditions.empty?
        query_string << " ORDER BY #{SQL.order(query.order[0])}" unless query.order.empty?
        query_string << " LIMIT #{query.limit}" if query.limit

        DataMapper.logger.debug query_string
      
        begin
          results = @connection.query(:queryString => query_string).result
        rescue SOAP::FaultError => e
          raise SalesforceAPI::ReadError, e.message
        end

        return nil unless results.records
        
        # This is the core logic that handles the difference between all/first
        (results.records || []).each do |result|
          props = props_from_result(properties_with_indexes, result, repository)
          arr ? set.load(props) : (break set.load(props, query))
        end
        
      end
      
      def props_from_result(properties_with_indexes, result, repo)
        properties_with_indexes.inject([]) do |accum, (prop, idx)|
          accum[idx] = result.send(soap_attr(prop, repo))
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
        results = @connection.update(arr)
        results.select {|r| r.success == true}.size
      end
      
      def create(resources)
        map = {}
        arr = resources.map do |resource|
          obj = make_sforce_obj(resource, resource.dirty_attributes, nil)
        end
        
        @connection.create(arr).each_with_index do |result, i|
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
        
        results = @connection.delete(keys)
        
        if results.all? {|r| r.success}
          results.size
        else
          raise SalesforceAPI::DeleteError, 
            results.find {|r| r.success == false}.errors.map {|e| "#{e.statusCode}: #{e.message}"}.join(", ")
        end
      end
      
      private
      def make_sforce_obj(query, attrs, key = nil)
        klass = SalesforceAPI.const_get(query.model.storage_name(query.repository.name))
        obj = klass.new
        obj.id = query.conditions.find {|op,prop,val| prop.key?}.last if key
        attrs.each do |prop,val|
          obj.send("#{soap_attr(prop, query.repository)}=", val)
        end
        obj
      end
      
      def soap_attr(prop, repository)
        prop.field(repository.name).gsub(/^[A-Z]/) {|m| m.downcase}
      end
      
    end
    
  end
end