module DataMapper::Salesforce
  class Type < ::DataMapper::Type
  end

  module Types
  end
end

dir = File.expand_path(File.dirname(__FILE__) / :types)

require dir / :serial
require dir / :boolean
require dir / :integer
require dir / :float
