$:.unshift "lib"
require "dm-salesforce/version"

Gem::Specification.new do |s|
  s.name = "dm-salesforce"
  s.version = DataMapper::Salesforce::VERSION
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.extra_rdoc_files = ["README.markdown", "LICENSE"]
  s.summary = "A DataMapper adapter to the Salesforce API"
  s.description = s.summary
  s.authors = ["Yehuda Katz", "Tim Carey-Smith", "Andy Delcambre"]
  s.email = "tcareysmith@engineyard.com"
  s.homepage = "http://github.com/tcareysmith/dm-salesforce"

  s.add_dependency "httpclient",     "=2.1.5.2"
  s.add_dependency "extlib",         "~> 0.9.9"
  s.add_dependency "dm-core",        "~> 0.10.1"
  s.add_dependency "dm-validations", "~> 0.10.1"
  s.add_dependency "dm-types",       "~> 0.10.1"
  s.add_dependency "soap4r",         "~> 1.5.8"

  s.require_path = 'lib'
  s.files = %w(LICENSE README.markdown Rakefile) + Dir.glob("lib/**/*")
end
