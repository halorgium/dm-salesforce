require 'rubygems'
require File.dirname(__FILE__)+'/../lib/dm-salesforce'

root = File.expand_path(File.dirname(__FILE__) + '/../') 
require 'fileutils'
sf_dir = ENV["SALESFORCE_DIR"] = root + '/tmp/dot_salesforce'
FileUtils.rm_r(sf_dir) if File.directory?(sf_dir)
FileUtils.mkdir_p(sf_dir)

module DataMapperSalesforce
  UserDetails = Struct.new(:username, :password)
end

load File.expand_path(root + '/config/database.rb')
