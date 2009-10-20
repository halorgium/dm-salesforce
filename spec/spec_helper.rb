root = File.expand_path(File.join(File.dirname(__FILE__), '/../'))
Bundler.require_env(:test)

require 'fileutils'
require File.dirname(__FILE__) + '/../lib/dm-salesforce'
require File.dirname(__FILE__) + '/fixtures/account'
require File.dirname(__FILE__) + '/fixtures/contact'

sf_dir = ENV["SALESFORCE_DIR"] = root + '/tmp/dot_salesforce'

FileUtils.rm_r(sf_dir) if File.directory?(sf_dir)
FileUtils.mkdir_p(sf_dir)

load File.expand_path(root + '/config/database.rb')
