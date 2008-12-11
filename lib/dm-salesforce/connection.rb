require 'soap/wsdlDriver'
require 'soap/header/simplehandler'
require "rexml/element"
require "fileutils"

module DataMapperSalesforce
  class Connection
    class Error          < StandardError; end
    class FieldNotFound  < Error; end
    class LoginFailed    < Error; end
    class SessionTimeout < Error; end

    class SOAPError      < Error
      def initialize(message, result)
        @result = result
        super("#{message}: #{result_message}")
      end

      def failed_records
        @result.reject {|r| r.success}
      end

      def result_message
        failed_records.map do |r|
          message_for_record(r)
        end.join("; ")
      end

      def message_for_record(record)
        record.errors.map {|e| "#{e.statusCode}: #{e.message}"}.join(", ")
      end
    end
    class CreateError    < SOAPError; end
    class QueryError     < SOAPError; end
    class DeleteError    < SOAPError; end
    class UpdateError    < SOAPError; end

    class HeaderHandler < SOAP::Header::SimpleHandler
      def initialize(tag, value)
        super(XSD::QName.new('urn:enterprise.soap.sforce.com', tag))
        @tag = tag
        @value = value
      end
      def on_simple_outbound
        @value
      end
    end

    def initialize(username, password, wsdl_path, organization_id = nil)
      @username, @password, @wsdl_path, @organization_id = URI.unescape(username), password, File.expand_path(wsdl_path), organization_id
      driver
    end
    attr_reader :wsdl_path, :user_id, :user_details

    def organization_id
      @user_details && @user_details.organizationId
    end

    def make_object(klass_name, values)
      klass = SalesforceAPI.const_get(klass_name)
      obj = klass.new
      values.each do |property,value|
        field = field_name_for(klass_name, property)
        obj.send("#{field}=", value)
      end
      obj
    end

    def field_name_for(klass_name, column)
      klass = SalesforceAPI.const_get(klass_name)
      fields = [column, column.camel_case, "#{column}__c".downcase]
      options = /^(#{fields.join("|")})$/i
      matches = klass.instance_methods(false).grep(options)
      if matches.any?
        matches.first
      else
        raise FieldNotFound,
            "You specified #{column} as a field, but neither #{fields.join(" or ")} exist. " \
            "Either manually specify the field name with :field, or check to make sure you have " \
            "provided a correct field name."
      end
    end

    def query(string)
      with_reconnection do
        driver.query(:queryString => string).result
      end
    rescue SOAP::FaultError => e
      raise QueryError.new(e.message, [])
    end

    def create(objects)
      call_api(:create, CreateError, "creating", objects)
    end

    def update(objects)
      call_api(:update, UpdateError, "updating", objects)
    end

    def delete(keys)
      call_api(:delete, DeleteError, "deleting", keys)
    end

    private
    def login
      generate_soap_classes
      driver = SalesforceAPI::Soap.new
      if @organization_id
        driver.headerhandler << HeaderHandler.new("LoginScopeHeader", :organizationId => @organization_id)
      end

      begin
        result = driver.login(:username => @username, :password => @password).result
      rescue SOAP::FaultError => error
        if error.faultcode.to_obj == "sf:INVALID_LOGIN"
          raise LoginFailed, "Could not login to Salesforce; #{error.faultstring.text}"
        else
          raise
        end
      end
      driver.endpoint_url = result.serverUrl
      driver.headerhandler << HeaderHandler.new("SessionHeader", "sessionId" => result.sessionId)
      driver.headerhandler << HeaderHandler.new("CallOptions", "client" => "client")
      @user_id = result.userId
      @user_details = result.userInfo
      driver
    end

    def driver
      @driver ||= login
    end

    def call_api(method, exception_class, message, args)
      with_reconnection do
        result = driver.send(method, args)
        if result.all? {|r| r.success}
          result
        else
          raise exception_class.new("Got some errors while #{message} Salesforce objects", result)
        end
      end
    end

    # Generate Ruby files and move them into .salesforce for future use
    def generate_soap_classes
      unless File.directory?(wsdl_api_dir) && Dir["#{wsdl_api_dir}/SalesforceAPI*.rb"].size == 3
        old_args = ARGV.dup
        unless File.file?(@wsdl_path)
          raise Errno::ENOENT, "Could not find the Salesforce WSDL at #{@wsdl_path}"
        end
        ARGV.replace %W(--wsdl #{@wsdl_path} --module_path SalesforceAPI --classdef SalesforceAPI --type client)
        load `which wsdl2ruby.rb`.chomp
        ARGV.replace old_args
        FileUtils.mkdir_p wsdl_api_dir
        FileUtils.mv Dir["SalesforceAPI*"], wsdl_api_dir
        FileUtils.rm Dir["SforceServiceClient.rb"]
      end

      $:.push wsdl_api_dir
      require "SalesforceAPIDriver"
    end

    def wsdl_api_dir
      "#{ENV["HOME"]}/.salesforce/#{wsdl_basename}"
    end

    def wsdl_basename
      @wsdl_basename ||= File.basename(@wsdl_path)
    end

    def with_reconnection(&block)
      yield
    rescue SOAP::FaultError => error
      retry_count ||= 0
      if error.faultcode.text == "sf:INVALID_SESSION_ID"
        $stderr.puts "Got a invalid session id; reconnecting"
        @driver = nil
        login
        retry_count += 1
        retry unless retry_count > 5
      else
        raise
      end

      raise SessionTimeout, "The Salesforce session could not be established"
    end
  end
end
