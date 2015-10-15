# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cloudstack-nagios/version'

Gem::Specification.new do |gem|
  gem.name          = "cloudstack-nagios"
  gem.version       = CloudstackNagios::VERSION
  gem.authors       = ["Nik Wolfgramm", "Martin Kolly"]
  gem.email         = ["nik.wolfgramm@gmail.com"]
  gem.description   = %q{cloudstack-nagios generates nagios configuration and checks for monitoring CloudStack with nagios.}
  gem.summary       = %q{cloudstack-nagios CloudStack monitoring tools for nagios}
  gem.homepage      = "https://github.com/swisstxt/cloudstack-nagios"
  gem.license       = 'MIT'

  gem.required_ruby_version = '>= 2.0'
  gem.files         = `git ls-files`.split($/)
  gem.executables   = ['cs-nagios']
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.rdoc_options  = %w[--line-numbers --inline-source]

  gem.add_development_dependency('rdoc')
  gem.add_development_dependency('rake', '~> 10.3.1')

  gem.add_dependency('cloudstack_client', '~> 1.0.4')
  gem.add_dependency('thor', '~> 0.19.1')
  gem.add_dependency('erubis', '~> 2.7.0')
  gem.add_dependency('sshkit', '~> 1.3.0')
  gem.add_dependency('highline', '~> 1.6.20')
end
