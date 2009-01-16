$:.push File.expand_path(File.dirname(__FILE__))

gem 'soap4r'
require 'dm-core'
require 'dm-validations'
require 'dm-salesforce/sql'
require 'dm-salesforce/extensions'
require 'dm-salesforce/adapter'
require 'dm-salesforce/connection'
require 'dm-salesforce/version'

DataMapper::Adapters::SalesforceAdapter = DataMapperSalesforce::Adapter
