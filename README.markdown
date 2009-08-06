dm-salesforce
=============

A gem that provides a Salesforce Adapter for DataMapper.

The wsdl is converted into Ruby classes and stored in ~/.salesforce. This automatically
happens the first time you use the salesforce adapter, so you don't need to worry about
generating Ruby code. It just works if you have the wsdl, directions for getting going 
are outlined below.

An example of using the adapter:

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


To get a test environment going with the free development tools you'll need to follow these steps.


* Get a developer account from http://force.salesforce.com
* Hit up https://login.salesforce.com, and login with the password they provided in your signup email
* Remember the password they force you to reset
* Grab the following from Salesforce's web UI
    *  Your Enterprise API WSDL [Click Setup][setup] and [Expand and Save As][getwsdl]
    *  Your API Token [Reset if needed][gettoken]
* Copy the WSDL file you downloaded to config/wsdl.xml
*   Copy and modify config/database.rb-example to use your info.  In this case my password is 'skateboards' and my API key is 'f938915c9cdc36ff5498881b':

        DataMapper.setup(:salesforce, {:adapter  => 'salesforce',
                                       :username => 'salesforceuser@mydomain.com',
                                       :password => 'skateboardsf938915c9cdc36ff5498881b',
                                       :path     => File.expand_path(File.dirname(__FILE__)+'/wsdl.xml'),
                                       :host     => ''})

        VALID_USER = DataMapperSalesforce::UserDetails.new('salesforceuser@mydomain.com', 'skateboardsf938915c9cdc36ff5498881b')
        VALID_SELF_SERVICE_USER = DataMapperSalesforce::UserDetails.new("quentin@example.com", "foo")
* Run 'bin/irb' and you should have access to the Account and Contact models

Special Thanks to Engine Yard Employees who helped
==================================================
* Corey Donohoe
* Andy Delcambre
* Ben Burkert
* Larry Diehl

[setup]: http://img.skitch.com/20090204-gaxdfxbi1emfita5dax48ids4m.jpg "Click on Setup"
[getwsdl]: http://img.skitch.com/20090204-nhurnuxwf5g3ufnjk2xkfjc5n4.jpg "Expand and Save"
[gettoken]: http://img.skitch.com/20090204-mnt182ce7bc4seecqbrjjxjbef.jpg "You can reset your token here"
