require File.dirname(__FILE__) + "/../config/rubundler"
r = Rubundler.new
r.setup_env

require r.root + '/lib/dm-salesforce'

module DataMapperSalesforce
  UserDetails = Struct.new(:username, :password)
end

load r.root + '/config/database.rb'
