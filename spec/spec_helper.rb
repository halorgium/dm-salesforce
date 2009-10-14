require File.dirname(__FILE__) + '/../vendor/gems/environment'

Bundler.require_env(:test)

require File.dirname(__FILE__) + '/../lib/dm-salesforce'
require File.dirname(__FILE__) + '/fixtures/account'
require File.dirname(__FILE__) + '/fixtures/contact'

root = File.expand_path(File.dirname(__FILE__) + '/../') 
require 'fileutils'
sf_dir = ENV["SALESFORCE_DIR"] = root + '/tmp/dot_salesforce'
FileUtils.rm_r(sf_dir) if File.directory?(sf_dir)
FileUtils.mkdir_p(sf_dir)

load File.expand_path(root + '/config/database.rb')
