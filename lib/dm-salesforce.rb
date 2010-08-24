require "fileutils"
require 'dm-core'
require 'dm-validations'
require 'soap/wsdlDriver'
require 'soap/header/simplehandler'
require "rexml/element"

module DataMapper::Salesforce
  UserDetails = Struct.new(:username, :password)
end

dir = File.expand_path(File.join(File.dirname(__FILE__), 'dm-salesforce'))

require dir / :resource
require dir / :connection
require dir / :connection / :errors
require dir / :soap_wrapper
require dir / :sql
require dir / :version
require dir / :adapter

case DataMapper::VERSION
when /^0\.10/ then
    require dir / :types
    ::DataMapper::Salesforce::Inflector = ::Extlib::Inflection
when /^1\.0/  then
    require dir / :property
    ::DataMapper::Salesforce::Inflector = ::DataMapper::Inflector
else raise "DataMapper #{DataMapper::VERSION} is an unsupported version"
end

DataMapper::Adapters::SalesforceAdapter = DataMapper::Salesforce::Adapter
