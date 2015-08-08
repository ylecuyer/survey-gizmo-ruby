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

  it 'should allow basic authentication configuration' do
    expect(SurveyGizmo.default_params).to eq({ 'user:md5' => 'test@test.com:5f4dcc3b5aa765d61d8327deb882cf99' })
  end

  it 'should allow changing user and pass' do
    SurveyGizmo.configure do |config|
      config.user = 'slimthug'
      config.password = 'fourfourz'
      config.api_version = 'v3'
    end

    expect(SurveyGizmo.default_params).to eq({ 'user:md5'=>'slimthug:836fd7e2961a094c01cb7ba78bac6a06' })
    expect(SurveyGizmo.base_uri).to eq('https://restapi.surveygizmo.com/v3')
  end
end
