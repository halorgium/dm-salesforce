Gem::Specification.new do |s|
  s.name = %q{dm-salesforce}
  s.version = "0.9.1"

  s.specification_version = 2 if s.respond_to? :specification_version=

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Yehuda Katz"]
  s.autorequire = %q{dm-salesforce}
  s.date = %q{2008-05-20}
  s.description = %q{A DataMapper adapter to the Salesforce API}
  s.email = %q{wycats@gmail.com}
  s.extra_rdoc_files = ["README.markdown", "LICENSE"]
  s.files = ["LICENSE", "README.markdown", "Rakefile", "lib/dm-salesforce.rb", "lib/salesforce_api.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://www.yehudakatz.com}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.1.1}
  s.summary = %q{A DataMapper adapter to the Salesforce API}
end
