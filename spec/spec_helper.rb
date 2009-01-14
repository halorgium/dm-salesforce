require File.dirname(__FILE__) + "/../config/rubundler"
r = Rubundler.new
r.setup_env

require 'fileutils'
sf_dir = ENV["SALESFORCE_DIR"] = r.root + '/tmp/dot_salesforce'
FileUtils.rm_r(sf_dir) if File.directory?(sf_dir)
FileUtils.mkdir_p(sf_dir)

require r.root + '/lib/dm-salesforce'

module DataMapperSalesforce
  UserDetails = Struct.new(:username, :password)
end

load r.root + '/config/database.rb'
