class Contact
  include DataMapper::Resource
  
  def self.default_repository_name
    :salesforce
  end

  def self.salesforce_id_properties
    [:id, :account_id]
  end

  property :id,    String, :serial => true
  property :first_name, String
  property :last_name, String
  property :email, String
  property :account_id, String

  belongs_to :account
end
