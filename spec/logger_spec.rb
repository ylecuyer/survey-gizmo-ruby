require 'spec_helper'

describe SurveyGizmo::Logger do
  let(:progname)    { 'TEST' }
  let(:severity)    { 'INFO' }
  let(:time_string) { '2015-04-15 05:46:30' }

  before(:each) do
    SurveyGizmo.configure do |config|
      config.api_token = 'king_of_the&whirled$'
      config.api_token_secret = 'dream/word'
    end
  end

  after(:each) do
    SurveyGizmo.reset!
  end

  it 'should mask unencoded api token' do
    config = SurveyGizmo.configuration
    formatted_message = config.logger.format_message(
      severity,
      time_string.to_time,
      progname,
      config.api_token
    )
    expect(
      formatted_message
    ).to match(
      /\[#{time_string} #{severity} \(\d+\)\] <SG_API_KEY>/
    )
  end

  it 'should mask percent encoded api token' do
    config = SurveyGizmo.configuration
    formatted_message = config.logger.format_message(
      severity,
      time_string.to_time,
      progname,
      CGI.escape(config.api_token)
    )
    expect(
      formatted_message
    ).to match(
      /\[#{time_string} #{severity} \(\d+\)\] <SG_API_KEY>/
    )
  end

  it 'should mask unencoded api token secret' do
    config = SurveyGizmo.configuration
    formatted_message = config.logger.format_message(
      severity,
      time_string.to_time,
      progname,
      config.api_token_secret
    )
    expect(
      formatted_message
    ).to match(
      /\[#{time_string} #{severity} \(\d+\)\] <SG_API_SECRET>/
    )
  end

  it 'should mask percent encoded api token secret' do
    config = SurveyGizmo.configuration
    formatted_message = config.logger.format_message(
      severity,
      time_string.to_time,
      progname,
      CGI.escape(config.api_token_secret)
    )
    expect(
      formatted_message
    ).to match(
      /\[#{time_string} #{severity} \(\d+\)\] <SG_API_SECRET>/
    )
  end
end
