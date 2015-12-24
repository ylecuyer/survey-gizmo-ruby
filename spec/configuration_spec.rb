require 'spec_helper'
require 'survey_gizmo/configuration'

describe SurveyGizmo::Configuration do
  before(:each) do
    SurveyGizmo.configure do |config|
      config.user = 'test@test.com'
      config.password = 'password'
    end
  end

  after(:each) do
    SurveyGizmo.reset!
  end

  it 'should allow changing user and pass' do
    SurveyGizmo.configure do |config|
      config.user = 'slimthug'
      config.password = 'fourfourz'
      config.api_version = 'v3'
    end

    expect(SurveyGizmo::Connection.instance.send(:connection).params).to eq({ 'user:md5'=>'slimthug:836fd7e2961a094c01cb7ba78bac6a06' })
  end
end
