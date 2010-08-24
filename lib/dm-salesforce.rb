require 'fileutils'
require 'dm-core'
require 'dm-validations'
require 'soap/wsdlDriver'
require 'soap/header/simplehandler'
require 'rexml/element'

module DataMapper::Salesforce
  UserDetails = Struct.new(:username, :password)
end

require 'dm-salesforce/resource'
require 'dm-salesforce/connection'
require 'dm-salesforce/connection/errors'
require 'dm-salesforce/soap_wrapper'
require 'dm-salesforce/sql'
require 'dm-salesforce/version'
require 'dm-salesforce/adapter'

case DataMapper::VERSION
when /^0\.10/ then
    require 'dm-salesforce/types'
    ::DataMapper::Salesforce::Inflector = ::Extlib::Inflection
when /^1\.0/  then
    require 'dm-salesforce/property'
    ::DataMapper::Salesforce::Inflector = ::DataMapper::Inflector
else raise "DataMapper #{DataMapper::VERSION} is an unsupported version"
end

DataMapper::Adapters::SalesforceAdapter = DataMapper::Salesforce::Adapter
