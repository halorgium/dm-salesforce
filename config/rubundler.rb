require 'yaml'

class Rubundler
  def setup_env
    unless ENV.key?("RUBUNDLED")
      ENV["RUBUNDLED"] = "1"
      ENV["PATH"] = "#{root}/gems/bin:#{ENV["PATH"]}"
      ENV["GEM_HOME"] = root + '/gems'
      ENV["GEM_PATH"] = root + '/gems'
    end

    require 'rubygems'
    gem_config.gems.each do |name,version|
      if version
        gem name, version
      else
        gem name
      end
    end
  end

  def setup_requirements
    gem_config.requirements.each do |name|
      require name
    end
  end

  def update
    save_gemrc
    install_gems
  end

  def save_gemrc
    File.open("#{root}/.gemrc", "w") do |f|
      f.puts({
        :sources => gem_config.sources,
        :update_sources => true,
        :bulk_threshold => 1000,
        :verbose => false,
        'gemhome' => root + '/gems',
        'gempath' => [root + '/gems'],
        :backtrace => false,
        :benchmark => false
      }.to_yaml)
    end
  end

  def install_gems
    gem_config.gems.each do |name,version|
      name_and_version = "#{name}"
      if version
        name_and_version << " --version='#{version}'"
      end

      next if system("#{command_source} spec #{name_and_version} >/dev/null 2>/dev/null")

      puts "Installing #{name_and_version}"
      unless system("#{command_source} install #{name_and_version} --no-ri --no-rdoc")
        abort "Failed to install: #{name}, #{version}"
      end
    end
  end

  def check(&block)
    instance_eval(&block)
  end

  def root
    @root ||= File.expand_path(File.dirname(__FILE__) + "/..")
  end

  def command_source
    "gem --config-file #{root}/.gemrc"
  end

  def gem_config
    @gem_config ||= ConfigFile.process(root + "/config/dependencies.rb")
  end

  class ConfigFile
    def self.process(path)
      c = new(path)
      c.process
    end

    def initialize(path)
      @path = path
    end

    def process
      instance_eval(File.read(@path), @path, 0)
      self
    end

    def sources
      @sources ||= []
    end

    def gems
      @gems ||= []
    end

    def requirements
      @requirements ||= []
    end

    private
      def add_source(uri)
        sources << uri
      end

      def add_gem(name, version = nil)
        gems << [name, version]
      end

      def add_dependency(name, version, *args)
        options = args.last.is_a?(Hash) ? args.pop : {}
        add_gem name, version
        if r = options[:require]
          requirements << r
        end
      end
  end
end
