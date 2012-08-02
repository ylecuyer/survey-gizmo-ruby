# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name        = "survey-gizmo-ruby"
  gem.homepage    = "http://github.com/RipTheJacker/survey-gizmo-ruby"
  gem.license     = "MIT"
  gem.summary     = %Q{gem to use the Survey Gizmo REST API}
  gem.description = %Q{gem to use the SurveyGizmo.com REST API, v3+}
  gem.email       = "self@ripthejacker.com"
  gem.authors     = ["Kabari Hendrick", "Chris Horn"]
  gem.files       = FileList['lib/**/*.rb', 'Gemfile*', '[A-Z]*', 'Rakefile', 'spec/**/*'].to_a
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :default => :spec

require 'yard'
YARD::Rake::YardocTask.new
