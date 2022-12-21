require 'spec_helper'
require 'survey_gizmo/configuration'

describe SurveyGizmo::Configuration do

  let(:api_token) { "token" }
  let(:api_token_secret) { "doken" }

  before(:each) do
    SurveyGizmo.configure do |config|
      config.api_token = api_token
      config.api_token_secret = api_token_secret
    end
  end

  after(:each) do
    SurveyGizmo.reset!
  end

  it "should allow changing user and pass" do
    # preload connection to verify that memoization is purged
    SurveyGizmo::Connection.send(:connection)

    SurveyGizmo.configure do |config|
      config.api_token = "slimthug"
      config.api_token_secret = "fourfourz"
    end

    expect(SurveyGizmo::Connection.send(:connection).params).to eq("api_token" => "slimthug", "api_token_secret" => "fourfourz")
  end

  context "thread safety" do
    it "is set from the last known configuration" do
      expect(SurveyGizmo.configuration.api_token).to eq(api_token)

      Thread.new do
        expect(SurveyGizmo.configuration.api_token).to eq(api_token)
      end
    end

    it "is not affected by a change in another thread" do
      expect(SurveyGizmo.configuration.api_token).to eq(api_token)

      Thread.new do
        SurveyGizmo.configure {|c| c.api_token = "new_token"}
        expect(SurveyGizmo.configuration.api_token).to eq("new_token")
      end.join

      expect(SurveyGizmo.configuration.api_token).to eq(api_token)
    end

    it "is not affected by a reset in another thread" do
      expect(SurveyGizmo.configuration.api_token).to eq(api_token)

      Thread.new do
        SurveyGizmo.reset!
        expect(SurveyGizmo.configuration.api_token).to eq(nil)
      end.join

      expect(SurveyGizmo.configuration.api_token).to eq(api_token)
    end

    it "updates the last known configuration" do
      expect(SurveyGizmo.configuration.api_token).to eq(api_token)

      Thread.new do
        SurveyGizmo.configure {|c| c.api_token = "new_token"}
        expect(SurveyGizmo.configuration.api_token).to eq("new_token")
      end.join
      Thread.new do
        expect(SurveyGizmo.configuration.api_token).to eq("new_token")
      end.join
    end

    describe ".configuration=" do
      let(:new_config) { SurveyGizmo::Configuration.new.tap { |c| c.api_token = "new_token" } }

      it "sets the configuration" do
        expect{
          SurveyGizmo.configuration = new_config
        }.to change {
          SurveyGizmo.configuration.api_token
        }.from(api_token).to("new_token")
      end

      it "does not affect other threads" do
        expect {
          Thread.new do
            SurveyGizmo.configuration = new_config
            expect(SurveyGizmo.configuration.api_token).to eq("new_token")
          end.join
        }.not_to change {
          SurveyGizmo.configuration.api_token
        }.from(api_token)
      end

      it "updates the last known configuration" do
        SurveyGizmo.configuration = new_config
        Thread.new do
          expect(SurveyGizmo.configuration.api_token).to eq("new_token")
        end.join
      end
    end
  end

  describe '#region=' do
    it 'should set US region by default' do
      SurveyGizmo.configure
      expect(SurveyGizmo.configuration.api_url).to eq('https://restapi.surveygizmo.com')
      expect(SurveyGizmo.configuration.api_time_zone).to eq('Eastern Time (US & Canada)')
    end

    it 'should set US region with :us symbol specified' do
      SurveyGizmo.configure do |config|
        config.region = :us
      end

      expect(SurveyGizmo.configuration.api_url).to eq('https://restapi.surveygizmo.com')
      expect(SurveyGizmo.configuration.api_time_zone).to eq('Eastern Time (US & Canada)')
    end

    it 'should set EU region with :eu symbol specified' do
      SurveyGizmo.configure do |config|
        config.region = :eu
      end

      expect(SurveyGizmo.configuration.api_url).to eq('https://restapi.surveygizmo.eu')
      expect(SurveyGizmo.configuration.api_time_zone).to eq('UTC')
    end

    it 'should fail with an unavailable region' do
      expect {
        SurveyGizmo.configure do |config|
          config.region = :cz
        end
      }.to raise_error(ArgumentError, "Unknown region: cz")
    end
  end

  describe 'locale' do
    it 'should set English locale by default' do
      SurveyGizmo.configure
      expect(SurveyGizmo.configuration.locale).to eq('English')
    end

    it 'should set Italian locale with Italian specified' do
      SurveyGizmo.configure do |config|
        config.locale = 'Italian'
      end

      expect(SurveyGizmo.configuration.locale).to eq('Italian')
    end
  end

  describe '#api=' do
    it 'should set surveygizmo by default' do
      SurveyGizmo.configure
      expect(SurveyGizmo.configuration.api_url).to eq('https://restapi.surveygizmo.com')
    end

    it 'should set surveygizmo api with :surveygizmo symbol specified' do
      SurveyGizmo.configure do |config|
        config.api = :surveygizmo
      end

      expect(SurveyGizmo.configuration.api_url).to eq('https://restapi.surveygizmo.com')
    end

    it 'should set alchemer api with :alchemer symbol specified' do
      SurveyGizmo.configure do |config|
        config.api = :alchemer
      end

      expect(SurveyGizmo.configuration.api_url).to eq('https://api.alchemer.com')
    end

    it 'should fail with an unavailable api' do
      expect {
        SurveyGizmo.configure do |config|
          config.api = :google
        end
      }.to raise_error(ArgumentError, "Unknown api: google")
    end
  end
end
