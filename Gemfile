source 'http://gems.rubyforge.org'

bin_path 'gbin'
disable_system_gems

gem "httpclient",     "=2.1.5.2"
gem "extlib",         "~> 0.9.9"
gem "dm-core",        "~> 0.10.1"
gem "dm-validations", "~> 0.10.1"
gem "dm-types",       "~> 0.10.1"
gem "do_sqlite3",     "~> 0.10.0"
gem "soap4r",         "~> 1.5.8", :require_as => [ ]

only :test do
  gem 'rspec',                     :require_as => %w(spec)
  gem 'rake'
  gem 'rcov'
  gem 'ruby-debug'
  gem 'bundler',      '~>0.6.0'
  gem 'ParseTree',                :require_as => 'parse_tree'
  gem 'dm-sweatshop'
  gem 'dm-migrations'
end

# vim:ft=ruby
