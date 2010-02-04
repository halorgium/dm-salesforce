Bundler.require(:default, :runtime, :test)

require 'fileutils'
root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
require File.join(root, 'lib', 'dm-salesforce')
require File.join(root, 'spec', 'fixtures', 'account')
require File.join(root, 'spec', 'fixtures', 'contact')

sf_dir = ENV["SALESFORCE_DIR"] = File.join(root, 'tmp', 'dot_salesforce')

FileUtils.rm_r(sf_dir) if File.directory?(sf_dir)
FileUtils.mkdir_p(sf_dir)

load File.expand_path(root + '/config/database.rb')
log_file = File.open(File.join(root, 'tmp', 'test.log'), 'w')
log_file.sync = true
DataMapper::Logger.new(log_file, 0)
