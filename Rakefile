require 'rubygems'
require 'rake/gempackagetask'
require 'rubygems/specification'
require 'date'

GEM = "dm-salesforce"
GEM_VERSION = "0.9.7.2"
AUTHOR = "Yehuda Katz"
EMAIL = "wycats@gmail.com"
HOMEPAGE = "http://www.yehudakatz.com"
SUMMARY = "A DataMapper adapter to the Salesforce API"

spec = Gem::Specification.new do |s|
  s.name = GEM
  s.version = GEM_VERSION
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.extra_rdoc_files = ["README.markdown", "LICENSE"]
  s.summary = SUMMARY
  s.description = s.summary
  s.author = AUTHOR
  s.email = EMAIL
  s.homepage = HOMEPAGE
  
  # Uncomment this to add a dependency
  # s.add_dependency "foo"
  s.add_dependency "dm-core", "~> 0.9.4"
  s.add_dependency "extlib", "~> 0.9.4"
  s.add_dependency "soap4r", "~> 1.5.8"
  
  s.require_path = 'lib'
  s.autorequire = GEM
  s.files = %w(LICENSE README.markdown Rakefile) + Dir.glob("{lib,specs}/**/*")
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end

desc "install the gem locally"
task :install => [:package] do
  sh %{sudo gem install pkg/#{GEM}-#{GEM_VERSION} --no-ri --no-rdoc}
end

desc "create a gemspec file"
task :make_spec do
  File.open("#{GEM}.gemspec", "w") do |file|
    file.puts spec.to_ruby
  end
end
