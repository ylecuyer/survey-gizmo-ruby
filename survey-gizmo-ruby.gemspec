# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |gem|
  gem.name = 'survey-gizmo-ruby'
  gem.version = '2.0.3'
  gem.authors = ['Kabari Hendrick', 'Chris Horn', 'Adrien Jarthon', 'Lumos Labs, Inc.']
  gem.email = ['adrien.jarthon@dimelo.com']
  gem.description = 'Gem to use the SurveyGizmo.com REST API, v3+'
  gem.summary = 'Gem to use the SurveyGizmo.com REST API, v3+'
  gem.homepage = 'http://github.com/RipTheJacker/survey-gizmo-ruby'
  gem.licenses = ['MIT']
  # Only tested with 2.1.5 but feel free to try it with older rubies
  # gem.required_ruby_version = '>= 2.1.5'

  gem.add_dependency 'activesupport', '>= 3.0'
  gem.add_dependency 'addressable'
  gem.add_dependency 'awesome_print'
  gem.add_dependency 'httparty'
  gem.add_dependency 'i18n'
  gem.add_dependency 'virtus', '>= 1.0.0'

  gem.add_development_dependency 'bluecloth'
  gem.add_development_dependency 'net-http-spy'
  gem.add_development_dependency 'rspec', '~> 2.11.0'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'webmock'
  gem.add_development_dependency 'yard'

  gem.files = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']
end
