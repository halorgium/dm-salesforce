require "fileutils"
require 'dm-core'
require 'dm-validations'
require 'soap/wsdlDriver'
require 'soap/header/simplehandler'
require "rexml/element"

dir = File.expand_path(File.join(File.dirname(__FILE__), 'dm-salesforce'))

require dir / :extensions
require dir / :resource
require dir / :connection
require dir / :connection / :errors
require dir / :soap_wrapper
require dir / :sql
require dir / :types
require dir / :version

require dir / :adapter

DataMapper::Adapters::SalesforceAdapter = DataMapperSalesforce::Adapter

module DataMapperSalesforce
  UserDetails = Struct.new(:username, :password)
end
