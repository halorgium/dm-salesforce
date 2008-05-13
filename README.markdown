dm-salesforce
=============

A gem that provides a Salesforce Adapter for DataMapper.

The URI for a Salesforce repository is:

    salesforce://username:password@salesforce.wsdl # relative wsdl path
    salesforce://username:password@/etc/salesforce.wsdl # absolute wsdl path
    
The wsdl is converted into Ruby classes and stored in ~/.salesforce. This automatically
happens the first time you use the salesforce adapter, so you don't need to worry about
generating Ruby code. It just works.

An example of using the adapter:

    class Account
      include DataMapper::Resource
    
      property :id, String, :key => true
      property :name, String
      property :description, String
      property :billing_city, String
      property :billing_postal_code, String
      property :billing_country, String
      property :billing_state, String
      property :billing_street, String
      property :fax, String
      property :phone, String
      property :type, String
      property :website, String
      has n, :contacts
    end

    class Contact
      include DataMapper::Resource
  
      property :id, String, :key => true
      property :title, String
      property :email, String
      property :first_name, String
      property :last_name, String
      property :home_phone, String
      property :mobile_phone, String
      property :phone, String
      belongs_to :account
    end

You can then do `Contact.all("account.name.like" => "%ruby%")`, which will get a list of all contacts
whose associated account's name is like `%ruby%`.