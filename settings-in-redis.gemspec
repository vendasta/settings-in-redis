# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'settings-in-redis/version'

Gem::Specification.new do |s|
  s.name        = 'settings-in-redis'
  s.version     = SettingsInRedis::VERSION
  s.authors     = ['Yesware, Inc']
  s.email       = ['engineering@yesware.com']
  s.summary     = %q{Global settings stored in Redis}
  s.description = %q{Ruby Gem that makes managing a table of key/value pairs easy. Think of it like a Hash stored in you database, that uses simple ActiveRecord like methods for manipulation.}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']

  s.add_runtime_dependency 'redis'
  s.add_runtime_dependency 'activesupport'
  s.add_runtime_dependency 'i18n' # required by activesupport

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'yard'
  s.add_development_dependency 'redcarpet'
end
