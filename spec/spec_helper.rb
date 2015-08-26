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
    @base = 'https://restapi.surveygizmo.com/v4'
    SurveyGizmo.configure do |config|
      config.user = 'test@test.com'
      config.password = 'password'
    end
  end
end
