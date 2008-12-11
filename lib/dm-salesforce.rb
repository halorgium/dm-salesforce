require File.dirname(__FILE__) + "/../config/rubundler"
r = Rubundler.new
r.setup_env
r.setup_requirements

$:.push File.expand_path(File.dirname(__FILE__))

require 'dm-salesforce/sql'
require 'dm-salesforce/adapter'
require 'dm-salesforce/connection'
require 'dm-salesforce/version'

DataMapper::Adapters::SalesforceAdapter = DataMapperSalesforce::Adapter
