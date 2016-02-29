require 'spec_helper'
require 'survey_gizmo/configuration'

describe SurveyGizmo::Configuration do
  before(:each) do
    SurveyGizmo.configure do |config|
      config.api_token = 'token'
      config.api_token_secret = 'doken'
    end
  end

  after(:each) do
    SurveyGizmo.reset!
  end

  it 'should allow changing user and pass' do
    SurveyGizmo.configure do |config|
      config.api_token = 'slimthug'
      config.api_token_secret = 'fourfourz'
    end

    expect(SurveyGizmo::Connection.send(:connection).params).to eq('api_token' => 'slimthug', 'api_token_secret' => 'fourfourz')
  end
end
