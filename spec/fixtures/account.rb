class Account
  include DataMapper::Resource
  
  def self.default_repository_name
    :salesforce
  end

  def self.salesforce_id_properties
    :id
  end

  property :id, String, :serial => true
  property :name, String
end
