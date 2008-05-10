$:.push File.expand_path(File.dirname(__FILE__))
require "rubygems"
gem "dm-core"
require "data_mapper"
require "fileutils"

module DataMapper
  module Adapters
    
    module SQL
      
      class << self
      
        def from_condition(condition)
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
            names = prop.relationships.map {|r| r.parent_model.storage_name}.join(".")
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
          when Array then " IN #{quote_value(value)}"
          else " = #{quote_value(value)}"
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
        @field_naming_convention = proc {|value| DataMapper::Inflection.camelize(value)}
        connect!
      end
      
      def connect!
        if @uri.host && @uri.path
          path = File.join(Dir.pwd, @uri.host, @uri.path)
        elsif @uri.host
          path = File.join(Dir.pwd, @uri.host)
        else
          path = @uri.path
        end

        basename = File.basename(path)

        # Generate Ruby files and move them into .salesforce for future use
        unless File.directory? "#{ENV["HOME"]}/.salesforce/#{basename}"
          old_args = ARGV.dup
          ARGV.replace %W(--wsdl #{File.expand_path(path)} --module_path SalesforceAPI --classdef SalesforceAPI --type client)
          load `which wsdl2ruby.rb`.chomp
          FileUtils.mkdir_p "#{ENV["HOME"]}/.salesforce/#{basename}"
          FileUtils.mv Dir["SalesforceAPI*"], "#{ENV["HOME"]}/.salesforce/#{basename}/"
          FileUtils.rm Dir["SforceServiceClient.rb"]
        end
        
        require "salesforce_api"
        @connection = SalesforceAPI::Connection.new(URI.unescape(@uri.user), @uri.password, "#{ENV["HOME"]}/.salesforce/#{basename}").driver
      end
      
      # Supported:
      #   
      def read_set(repository, query)
        properties = query.fields
        properties_with_indexes = Hash[*properties.zip((0...properties.size).to_a).flatten]
        
        set = Collection.new(repository, query.model, properties_with_indexes)
        
        conditions = query.conditions.map {|c| SQL.from_condition(c)}.compact.join(") AND (")
        
        query_string = "SELECT #{query.fields.map {|f| f.field}.join(", ")} from #{query.model_name}"
        query_string << " WHERE (#{conditions})" unless conditions.empty?
        query_string << " ORDER BY #{SQL.order(query.order[0])}" unless query.order.empty?
        query_string << " LIMIT #{query.limit}" if query.limit

        DataMapper.logger.debug query_string
        
        results = @connection.query(:queryString => query_string).result
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
      
      def update(repository, resource)
        properties = resource.dirty_attributes

        if properties.empty?
          return false
        else
          klass = SalesforceAPI.const_get(resource.class.storage_name(resource.repository.name))
          obj = klass.new
          obj.id = resource.key.first
          properties.each do |prop|
            obj.send("#{soap_attr(prop)}=", resource.instance_variable_get(prop.instance_variable_name))
          end

          result = @connection.update([obj])
          result[0].success == true
        end
      end
      
      private
      def soap_attr(prop)
        prop.field.gsub(/^[A-Z]/) {|m| m.downcase}
      end
      
    end
    
  end
end