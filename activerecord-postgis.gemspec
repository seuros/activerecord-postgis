# frozen_string_literal: true

require_relative 'lib/active_record/connection_adapters/postgis/version'

Gem::Specification.new do |spec|
  spec.name = 'activerecord-postgis'
  spec.version = Activerecord::ConnectionAdapters::PostGIS::VERSION
  spec.authors = [ 'Abdelkader Boudih' ]
  spec.email = [ 'terminale@gmail.com' ]

  spec.summary = 'PostGIS Type support for ActiveRecord'
  spec.description = spec.summary
  spec.homepage = 'https://github.com/seuros/activerecord-postgis'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.2.0'

  # spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/master/CHANGELOG.md"

  gemspec = File.basename(__FILE__)
  spec.files = Dir.glob('{lib}/**/*') + [ gemspec, 'LICENSE.md', 'CHANGELOG.md', 'README.md' ]
  spec.require_paths = [ 'lib' ]

  spec.add_dependency 'activerecord', '>= 7.2.0', '< 8.1'
  spec.add_dependency 'pg'
  spec.add_dependency 'rgeo-activerecord', '>= 8.0'
end
