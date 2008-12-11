add_source "http://gems.rubyforge.org/"

add_gem 'rspec'
add_gem 'rake'
add_gem 'rcov'
add_gem 'hoe'

add_dependency "extlib", "~> 0.9.7"
add_dependency "dm-core", "~> 0.9.7", :require => 'dm-core'
add_dependency "soap4r", "~> 1.5.8"
