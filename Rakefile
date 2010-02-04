require 'rake/gempackagetask'
require 'rubygems/specification'
require 'bundler'
require 'date'
require 'pp'
require 'tmpdir'

Bundler.require(:default, :runtime)
require File.dirname(__FILE__) + '/lib/dm-salesforce'

GEM = "dm-salesforce"
GEM_VERSION = DataMapper::Salesforce::VERSION
AUTHORS = ["Yehuda Katz", 'Tim Carey-Smith']
EMAIL = "wycats@gmail.com"
HOMEPAGE = "http://www.yehudakatz.com"
SUMMARY = "A DataMapper adapter to the Salesforce API"

@spec = Gem::Specification.new do |s|
  s.name = GEM
  s.version = GEM_VERSION
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.extra_rdoc_files = ["README.markdown", "LICENSE"]
  s.summary = SUMMARY
  s.description = s.summary
  s.authors = AUTHORS
  s.email = EMAIL
  s.homepage = HOMEPAGE

  bundle = Bundler::Definition.from_gemfile('Gemfile')
  bundle.dependencies.each do |dep|
    next unless dep.groups.include?(:runtime)
    s.add_dependency(dep.name, dep.version_requirements.to_s)
  end

  s.require_path = 'lib'
  s.files = %w(LICENSE README.markdown Rakefile) + Dir.glob("lib/**/*")
end

Rake::GemPackageTask.new(@spec) do |pkg|
  pkg.gem_spec = @spec
end

desc "install the gem locally"
task :install => [:package] do
  sh %{gem install pkg/#{GEM}-#{GEM_VERSION} --no-ri --no-rdoc}
end

task :default => 'spec'
require 'spec'
require 'spec/rake/spectask'
desc "Run specs"
Spec::Rake::SpecTask.new(:spec) do |t|
  t.spec_opts << %w(-fs --color) << %w(-O spec/spec.opts)
  t.spec_opts << '--loadby' << 'random'
  t.spec_files = Dir["spec/**/*_spec.rb"]
  t.rcov = ENV.has_key?('NO_RCOV') ? ENV['NO_RCOV'] != 'true' : true
  t.rcov_opts << '--exclude' << "~/.salesforce,gems,vendor,/var/folders,spec,config,tmp"
  t.rcov_opts << '--text-summary'
  t.rcov_opts << '--sort' << 'coverage' << '--sort-reverse'
end

desc "Release the version"
task :release => :repackage do
  version = DataMapperSalesforce::VERSION
  puts "Releasing #{version}"

  `git show-ref tags/v#{version}`
  unless $?.success?
    abort "There is no tag for v#{version}"
  end

  `git show-ref heads/releasing`
  if $?.success?
    abort "Remove the releasing branch, we need it!"
  end

  puts "Checking out to the releasing branch as the tag"
  system("git", "checkout", "-b", "releasing", "tags/v#{version}")

  puts "Reseting back to master"
  system("git", "checkout", "master")
  system("git", "branch", "-d", "releasing")

  current = @spec.version.to_s + ".0"
  next_version = Gem::Version.new(current).bump

  puts "Changing the version to #{next_version}."

  version_file = File.dirname(__FILE__)+"/lib/#{GEM}/version.rb"
  File.open(version_file, "w") do |f|
    f.puts <<-EOT
module DataMapperSalesforce
  VERSION = "#{next_version}"
end
    EOT
  end

  puts "Committing the version change"
  system("git", "commit", version_file, "-m", "Next version: #{next_version}")

  puts "Push the commit up! if you don't, you'll be hunted down"
end
