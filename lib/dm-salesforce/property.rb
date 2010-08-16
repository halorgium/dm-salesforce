module DataMapper::Salesforce
  module Property
  end
end

dir = File.expand_path(File.dirname(__FILE__) / :property)

require dir / :serial
require dir / :boolean
require dir / :integer
require dir / :float

