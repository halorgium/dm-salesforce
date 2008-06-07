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
          "#{direction.property.field} #{direction.direction.upcase}"
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
      
      def read_set(repository, query)
        properties = query.fields
        properties_with_indexes = Hash[*properties.zip((0...properties.size).to_a).flatten]
        
        set = Collection.new(query)
        
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
          
        results = results.size > 0 ? results.records : []
        
        results.each do |result|
          props = properties_with_indexes.inject([]) do |accum, (prop, idx)|
            accum[idx] = result.send(soap_attr(prop))
            accum
          end
          set.load(props, query.reload?)
        end
        
        set
      end
      
      def read(repository, resource, key)
        read_set(repository, DataMapper::Query.new(repository, resource, 
          {resource.key(repository.name)[0].name.eql => key[0]})).first
      end
      
      def update(repository, resource)
        properties = resource.dirty_attributes

        if properties.empty?
          return false
        else
          obj = make_sforce_obj(resource, properties, resource.key.first)
          result = @connection.update([obj])
          result[0].success == true
        end
      end
      
      def create(repository, resource)
        properties = resource.dirty_attributes
        
        obj = make_sforce_obj(resource, properties, nil)
        
        results = @connection.create([obj])
        
        if results[0].success
          key = resource.class.key(repository.name).first
          resource.instance_variable_set(key.instance_variable_name, results[0].id)
        else
          raise SalesforceAPI::CreateError, results[0].errors.map {|e| "#{e.statusCode}: #{e.message}"}.join(", ")
        end
        
        true
      end
      
      def delete(repository, resource)
        key = resource.key.first
        
        results = @connection.delete([key])
        if results[0].success
          true
        else
          raise SalesforceAPI::DeleteError, results[0].errors.map {|e| "#{e.statusCode}: #{e.message}"}.join(", ")
        end
      end
      
      private
      def make_sforce_obj(resource, props, key = nil)
        klass = SalesforceAPI.const_get(resource.class.storage_name(resource.repository.name))
        obj = klass.new
        obj.id = key if key
        props.each do |prop|
          obj.send("#{soap_attr(prop)}=", resource.instance_variable_get(prop.instance_variable_name))
        end
        obj
      end
      
      def soap_attr(prop)
        prop.field.gsub(/^[A-Z]/) {|m| m.downcase}
      end
      
    end
    
  end
end