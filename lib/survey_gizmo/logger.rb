require 'logger'

module SurveyGizmo
  class Logger < ::Logger
    def format_message(severity, timestamp, progname, msg)
      msg.gsub!(/#{Regexp.quote(SurveyGizmo.configuration.api_token_secret)}/, '<SG_API_KEY>') if SurveyGizmo.configuration.api_token
      msg.gsub!(/#{Regexp.quote(SurveyGizmo.configuration.api_token_secret)}/, '<SG_API_SECRET>') if SurveyGizmo.configuration.api_token_secret

      "#{timestamp.strftime('%Y-%m-%d %H:%M:%S')} #{severity} #{msg}\n"
    end
  end
end
