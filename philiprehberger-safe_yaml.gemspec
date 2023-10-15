# frozen_string_literal: true

require_relative 'lib/philiprehberger/safe_yaml/version'

Gem::Specification.new do |spec|
  spec.name          = 'philiprehberger-safe_yaml'
  spec.version       = Philiprehberger::SafeYaml::VERSION
  spec.authors       = ['Philip Rehberger']
  spec.email         = ['me@philiprehberger.com']

  spec.summary       = 'Safe YAML loading with restricted types, schema validation, and size limits'
  spec.description   = 'Safe YAML loading with restricted types, schema validation, and size limits. ' \
                       'Wraps YAML.safe_load with sensible defaults and provides a DSL for validating ' \
                       'parsed YAML structure against a defined schema.'
  spec.homepage      = 'https://philiprehberger.com/open-source-packages/ruby/philiprehberger-safe_yaml'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri']       = 'https://github.com/philiprehberger/rb-safe-yaml'
  spec.metadata['changelog_uri']         = 'https://github.com/philiprehberger/rb-safe-yaml/blob/main/CHANGELOG.md'
  spec.metadata['bug_tracker_uri']       = 'https://github.com/philiprehberger/rb-safe-yaml/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir['lib/**/*.rb', 'LICENSE', 'README.md', 'CHANGELOG.md']
  spec.require_paths = ['lib']
end
