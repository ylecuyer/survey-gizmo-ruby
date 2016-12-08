require 'logger'

module SurveyGizmo
  class Logger < ::Logger
    def format_message(severity, timestamp, progname, message)
      api_token = SurveyGizmo.configuration.api_token
      api_token_secret = SurveyGizmo.configuration.api_token_secret

      message.gsub!(
        /#{Regexp.quote(api_token)}/,
        '<SG_API_KEY>'
      ) if api_token

      message.gsub!(
        /#{Regexp.quote(api_token_secret)}/,
        '<SG_API_SECRET>'
      ) if api_token_secret

      # in case the tokens are percent encoded according to CGI query spec
      message.gsub!(
        /#{Regexp.quote(CGI.escape(api_token))}/,
        '<SG_API_KEY>'
      ) if api_token

      message.gsub!(
        /#{Regexp.quote(CGI.escape(api_token_secret))}/,
        '<SG_API_SECRET>'
      ) if api_token_secret

      "#{timestamp.strftime('%Y-%m-%d %H:%M:%S')} #{severity} #{message}\n"
    end
  end
end
