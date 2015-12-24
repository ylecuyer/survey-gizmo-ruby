require 'survey-gizmo-ruby'
require 'active_support/json'
require 'active_support/ordered_hash'
require 'webmock/rspec'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.include SurveyGizmoSpec::Methods

  config.before(:each) do
    SurveyGizmo.configure do |config|
      config.user = 'test@test.com'
      config.password = 'password'
      config.api_version = 'v4'
    end

    Pester.configure do |config|
      config.environments[:survey_gizmo_ruby][:logger] = ::Logger.new(nil)
    end

    @base = "#{SurveyGizmo.configuration.api_url}/#{SurveyGizmo.configuration.api_version}"
  end
end
