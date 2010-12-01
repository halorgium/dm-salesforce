require 'rake/gempackagetask'
require 'rubygems/specification'
require 'date'
require 'pp'
require 'tmpdir'

require 'bundler/setup'

Bundler.require

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
