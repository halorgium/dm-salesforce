#!/usr/bin/env ruby
#
# Another quick testing program for working on this library.  Makes it
# easy to get up and running from the gem source and into a debugger.
# Uses ruby-debug instead of IRB so you can drop indiscriminate
# debugger lines anywhere.  Probably some way to do this with IRB but,
# well, fuckit.
#

BEGIN {
    require 'rubygems'

    require 'ruby-debug'
    Debugger.start

    require 'merb-core' # need this for dependency(..)
    require 'config/dependencies.rb'
    require 'lib/dm-salesforce.rb' # this gem
    require 'dm-aggregates' # optional, for Model.count

    db_config = {
        :adapter  => 'salesforce',
        :username => 'api-user@example.org',
        :password => 'passwordAPIKEY',
        :path     => '/path/to/salesforce.wsdl',
        :apidir   => '/tmp',
        :host     => '',
    }

    DataMapper::Logger.new(STDOUT, :debug)
    DataMapper.setup(:default, db_config)
} # BEGIN

#
# Some test classes.
#

class Account
  include DataMapper::Resource

  property :id,          String, :key => true, :salesforce_id => true
  property :name,        String
  property :description, String
  property :fax,         String
  property :phone,       String
  property :type,        String
  property :website,     String

  has 0..n, :contacts
end

class Contact
  include DataMapper::Resource

  property :id,         String, :serial => true, :salesforce_id => true
  property :first_name, String
  property :last_name,  String
  property :email,      String
  property :account_id, String, :salesforce_id => true

  belongs_to :account
end


#
# And now we play.
#

puts Account.first.inspect
puts Account.count.inspect

debugger

exit

