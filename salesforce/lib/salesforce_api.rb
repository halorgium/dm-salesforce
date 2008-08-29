gem "soap4r", ">= 1.5.8"
require 'soap/wsdlDriver'
require 'soap/header/simplehandler'
require "rexml/element"

module SalesforceAPI

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
  
  class Connection
    attr_accessor :driver
    def initialize(username, password)      
      @driver = SalesforceAPI::Soap.new
      begin
        result = driver.login(:username => username, :password => password).result
      rescue SOAP::FaultError => e
        return nil
      end
      driver.endpoint_url = result.serverUrl
      driver.headerhandler << HeaderHandler.new("SessionHeader", "sessionId" => result.sessionId)
      driver.headerhandler << HeaderHandler.new("CallOptions", "client" => "client")
      @user_details = result.userInfo
    end
  end
end
