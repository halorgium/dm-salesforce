class Account
  include DataMapper::Salesforce::Resource

  def self.default_repository_name
    :salesforce
  end

  def self.salesforce_id_properties
    :id
  end

  property :id,                  Serial
  property :name,                String,  :nullable => false
  property :active,              Boolean, :field => 'Active_L_C__c'
  property :annual_revenue,      Float
  property :number_of_employees, Integer

  has n, :contacts
end

Account.fix {{
  :name                 => Randgen.first_name,
  :active               => true,
  :annual_revenue       => rand(1_000).to_f / 100,
  :number_of_employees  => (1..10).pick,
}}
