dm-salesforce
=============

A gem that provides a Salesforce Adapter for DataMapper 0.10.x, and basic 1.0.x
support.

If you're looking for ongoing DM1 support,
[dm-salesforce-adapter](http://github.com/cloudcrowd/dm-salesforce-adapter) is
actively maintained to support it so use that instead.

There are older versions of dm-salesforce specifically for 0.9.x, but they are
no longer supported.

What it looks like
==================

    class Account
      include DataMapper::Salesforce::Resource

      def self.default_repository_name
        :salesforce
      end

      # Old method for declaring which fields are Salesforce-style IDs.  Alternatively,
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

See [the fixtures](http://github.com/jpr5/dm-salesforce/tree/master/spec/fixtures) for more
examples.

How it works
============

Salesforce provides an XML-based WSDL definition of an existing schema/object model for
download.  The dm-salesforce adapter uses this WSDL to auto-generate a SOAP-based Ruby
driver and classes, which is then used to implement a basic, low-level DataMapper Adapter.

Upon first access, the driver and classes are cached locally on disk in one of the
following locations (in order of precedence):

  * In `apidir`, defined in `database.yml` (see included database.yml-example)
  * In `ENV['SALESFORCE_DIR']`
  * In `ENV['HOME']/.salesforce/`

Getting set up
==============

1. Obtain a working salesforce.com account

2. Get a valid security token (if you don't already have one)
    * Login to `https://login.salesforce.com`
    * [Click "Setup"][setup]
    * [Click "Personal Setup" / "My Personal Information" / "Reset My Security Token"][gettoken]
        * This will send a message to your account's email address with an "API key"
          (looks like a 24 character token)

3. Get the Enterprise WSDL for your object model
    * Login to `https://login.salesforce.com`
    * [Click "Setup"][setup]
    * [Click "App Setup" / "Develop" / "API"][getwsdl]
    * Click "Generate Enterprise WSDL", then click the "Generate" button
    * Save that to an .xml file somewhere (path/extension doesn't matter - you specify it
      in database.yml / DataMapper.setup)

4. Copy and modify config/example.rb to use your info
    * The :password field is the concatenation of your login password and the API key
    * If your password is 'skateboards' and API key is 'f938915c9cdc36ff5498881b', then
      the :password field you specify to DataMapper.setup should be
      'skateboardsf938915c9cdc36ff5498881b'

Run 'ruby example.rb' and you should have access to the Account and Contact models (schema
differences withstanding).

**Don't forget to:**

* Retrieve a new copy of your WSDL anytime you make changes to your Salesforce schema
* Wipe the auto-generated SOAP classes anytime you update your WSDL


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
* Jason Snell

[setup]: http://img.skitch.com/20090204-gaxdfxbi1emfita5dax48ids4m.jpg "Click on Setup"
[getwsdl]: http://img.skitch.com/20090204-nhurnuxwf5g3ufnjk2xkfjc5n4.jpg "Expand and Save"
[gettoken]: http://img.skitch.com/20090204-mnt182ce7bc4seecqbrjjxjbef.jpg "You can reset your token here"
