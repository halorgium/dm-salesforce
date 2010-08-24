module DataMapper::Salesforce
  class Type < ::DataMapper::Type
  end

  module Types
  end

  Property = Types
end

require 'dm-salesforce/types/serial'
require 'dm-salesforce/types/boolean'
require 'dm-salesforce/types/integer'
require 'dm-salesforce/types/float'
