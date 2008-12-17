add_source "http://gems.rubyforge.org/"

add_gem 'rspec'
add_gem 'rake'
add_gem 'rcov'
add_gem 'hoe'
add_gem 'ruby-debug'

add_dependency "extlib", "~> 0.9.9"
add_dependency "dm-core", "~> 0.9.8", :require => 'dm-core'
add_dependency "dm-validations", "~> 0.9.8", :require => 'dm-validations'
add_dependency "soap4r", "~> 1.5.8"
add_dependency "data_objects", "0.9.9"
add_dependency "do_sqlite3", "0.9.9"
