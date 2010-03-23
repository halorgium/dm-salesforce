dm-salesforce
=============

A gem that provides a Salesforce Adapter for DataMapper 0.10.x.
There are older versions of dm-salesforce specifically for 0.9.x.

The WSDL is automatically converted into Ruby classes upon the first
invocation of the dm-salesforce adapter.  The classes in turn get
cached locally in one of the following locations, in order of
precedence:

    :repositories:salesforce:apidir (see included database.yml-example)
    ENV["SALESFORCE_DIR"]
    ~/.salesforce/

It should just work if you have the WSDL file.  Directions for getting going are outlined
below.

A quick example of using the adapter (schema differences withstanding):

    class Account
      include DataMapper::Salesforce::Resource

      def self.default_repository_name
        :salesforce
      end

      # Old method for stipulating which fields are Salesforce-style IDs.  Alternatively,
      # can use the Salesforce-specific Serial custom DM type (see next model).
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
                                   :username => 'salesforceuser@mydomain.com',
                                   :password => 'skateboardsf938915c9cdc36ff5498881b',
                                   :path     => '/path/to/wsdl.xml',
                                   :host     => ''})

    account = Account.first
    account.is_awesome = true
    account.save


To quickly test programmatic access with the DataMapper Salesforce adapter, follow these steps:

* Obtain a working salesforce.com account
* Get a security token (if you don't already have one)
  * Login to https://login.salesforce.com
  * [Click "Setup"][setup]
  * [Click "Personal Setup" / "My Personal Information" / "Reset My Security Token"][gettoken]
   * This will send a message to your account's email address with an "API key" (looks like a 24 character hash)
* Get the Enterprise WSDL for your object model
  * Login to https://login.salesforce.com
  * [Click "Setup"][setup]
  * [Click "App Setup" / "Develop" / "API"][getwsdl]
  * Click "Generate Enterprise WSDL", then click the "Generate" button
  * Save that to to an .xml file somewhere (path/extension doesn't matter - you specify it in database.yml / DataMapper.setup)
* Copy and modify config/example.rb to use your info
 * The :password field is the concatenation of your login password and the API key
 * If your password is 'skateboards' and API key is 'f938915c9cdc36ff5498881b', then the :password field you pass to DataMapper.setup should be 'skateboardsf938915c9cdc36ff5498881b'
* Run 'ruby example.rb' and you should have access to the Account and Contact models (schema differences withstanding)

Don't forget:

* To retrieve a new copy of your WSDL anytime you change your Salesforce schema
* To reset/wipe the auto-generated SOAP classes anytime you update your WSDL


Special Thanks to those who helped
==================================================
* Yehuda Katz
* Corey Donohoe
* Tim Carey-Smith
* Andy Delcambre
* Ben Burkert
* Larry Diehl
* Jordan Ritter
* Martin Emde

[setup]: http://img.skitch.com/20090204-gaxdfxbi1emfita5dax48ids4m.jpg "Click on Setup"
[getwsdl]: http://img.skitch.com/20090204-nhurnuxwf5g3ufnjk2xkfjc5n4.jpg "Expand and Save"
[gettoken]: http://img.skitch.com/20090204-mnt182ce7bc4seecqbrjjxjbef.jpg "You can reset your token here"
