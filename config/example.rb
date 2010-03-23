#!/usr/bin/ruby

require 'rubygems'
require 'dm-core'
require 'dm-salesforce'

class Account
  include DataMapper::Salesforce::Resource

  def self.default_repository_name
    :salesforce
  end

  # Old method for designating which fields are Salesforce-style IDs.  Alternatively, can
  # use the Salesforce-specific Serial custom DM type (see next model).
  def self.salesforce_id_properties
    :id
  end

  property :id,          String, :key => true
  property :name,        String
  property :description, String
  property :fax,         String
  property :phone,       String
  property :type,        String
  property :website,     String
  property :is_awesome,  Boolean

  has 0..n, :contacts
end

class Contact
  include DataMapper::Salesforce::Resource

  def self.default_repository_name
    :salesforce
  end

  property :id,         Serial
  property :first_name, String
  property :last_name,  String
  property :email,      String

  belongs_to :account
end

DataMapper.setup(:salesforce, {:adapter  => 'salesforce',
                               :username => 'api-user@example.org',
                               :password => 'PASSWORD',
                               :path => "/path/to/the/wsdl/for/salesforce",
                               :apidir  => ENV['SALESFORCE_DIR'] || "/tmp/dm-salesforce_#{$$}",
                               :host => ''})

puts Account.first.inspect
