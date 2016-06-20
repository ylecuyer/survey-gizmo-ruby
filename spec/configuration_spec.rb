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
    # preload connection to verify that memoization is purged
    SurveyGizmo::Connection.send(:connection)

    SurveyGizmo.configure do |config|
      config.api_token = 'slimthug'
      config.api_token_secret = 'fourfourz'
    end

    expect(SurveyGizmo::Connection.send(:connection).params).to eq('api_token' => 'slimthug', 'api_token_secret' => 'fourfourz')
  end

  describe '#api=' do
    it 'should set US region by default' do
      SurveyGizmo.configure
      expect(SurveyGizmo.configuration.api_url).to eq('https://restapi.surveygizmo.com')
      expect(SurveyGizmo.configuration.api_locale).to eq('Eastern Time (US & Canada)')
    end

    it 'should set US region with :us symbol specified' do
      SurveyGizmo.configure do |config|
        config.region = :us
      end

      expect(SurveyGizmo.configuration.api_url).to eq('https://restapi.surveygizmo.com')
      expect(SurveyGizmo.configuration.api_locale).to eq('Eastern Time (US & Canada)')
    end

    it 'should set EU region with :eu symbol specified' do
      SurveyGizmo.configure do |config|
        config.region = :eu
      end

      expect(SurveyGizmo.configuration.api_url).to eq('https://restapi.surveygizmo.eu')
      expect(SurveyGizmo.configuration.api_locale).to eq('Berlin')
    end

    it 'should fail with an unavailable region' do
      expect {
        SurveyGizmo.configure do |config|
          config.region = :cz
        end
      }.to raise_error
    end

  end

end
