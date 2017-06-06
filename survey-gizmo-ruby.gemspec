# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'survey_gizmo/version'

Gem::Specification.new do |gem|
  gem.name = 'survey-gizmo-ruby'
  gem.version = SurveyGizmo::VERSION
  gem.authors = ['Kabari Hendrick', 'Chris Horn', 'Adrien Jarthon', 'Lumos Labs, Inc.']
  gem.email = ['adrien.jarthon@dimelo.com']
  gem.description = 'Gem to use the SurveyGizmo.com REST API, v3+'
  gem.summary = 'Gem to use the SurveyGizmo.com REST API, v3+'
  gem.homepage = 'http://github.com/jarthod/survey-gizmo-ruby'
  gem.licenses = ['MIT']
  gem.required_ruby_version = '>= 1.9'

  gem.add_dependency 'activesupport', '>= 3.0', '< 6.0'
  gem.add_dependency 'addressable', '~> 2'
  gem.add_dependency 'awesome_print', '~> 1'
  gem.add_dependency 'faraday', '>= 0.9.1', '~> 0.9'
  gem.add_dependency 'faraday_middleware', '~> 0.9'
  gem.add_dependency 'retriable', '>= 2.0', '< 4.0'
  gem.add_dependency 'i18n'
  gem.add_dependency 'virtus', '>= 1.0.0'

  gem.add_development_dependency 'rspec', '~> 3.4.0'
  gem.add_development_dependency 'rake', '~> 12.0.0'
  gem.add_development_dependency 'webmock'
  gem.add_development_dependency 'yard'

  gem.files = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']
end
