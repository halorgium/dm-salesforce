module DataMapperSalesforce
  class SoapWrapper
    class ClassesFailedToGenerate < StandardError; end

    attr_reader :module_name, :driver_name, :wsdl_path, :api_dir

    def initialize(module_name, driver_name, wsdl_path, api_dir)
      @module_name, @driver_name, @wsdl_path, @api_dir = module_name, driver_name, File.expand_path(wsdl_path), File.expand_path(api_dir)
      generate_soap_classes
      driver
    end

    def driver
      @driver ||= Object.const_get(module_name).const_get(driver_name).new
    end

    def generate_soap_classes
      unless File.file?(wsdl_path)
        raise Errno::ENOENT, "Could not find the WSDL at #{wsdl_path}"
      end

      unless File.directory?(wsdl_api_dir)
        FileUtils.mkdir_p wsdl_api_dir
      end

      generate_files unless files_exist?

      $:.push wsdl_api_dir
      require "#{module_name}Driver"
      $:.delete wsdl_api_dir
    end

    # Good candidate for shipping out into a Rakefile.
    def generate_files
      require 'wsdl/soap/wsdl2ruby'

      wsdl2ruby          = WSDL::SOAP::WSDL2Ruby.new
      wsdl2ruby.logger   = $LOG if $LOG
      wsdl2ruby.location = wsdl_path
      wsdl2ruby.basedir  = wsdl_api_dir

      wsdl2ruby.opt.merge!({
        'classdef'         => module_name,
        'module_path'      => module_name,
        'mapping_registry' => nil,
        'driver'           => nil,
        'client_skelton'   => nil,
      })

      wsdl2ruby.run

      raise ClassesFailedToGenerate unless files_exist?
    end

    def files_exist?
      ["#{module_name}.rb", "#{module_name}MappingRegistry.rb", "#{module_name}Driver.rb"].all? do |name|
        File.exist?("#{wsdl_api_dir}/#{name}")
      end
    end

    def wsdl_api_dir
      "#{api_dir}/#{File.basename(wsdl_path)}"
    end
  end
end

