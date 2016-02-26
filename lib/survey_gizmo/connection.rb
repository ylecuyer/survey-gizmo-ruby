require 'active_support/core_ext/module/delegation'

module SurveyGizmo
  class Connection
    class << self
      delegate :put, :get, :delete, :post, to: :connection

      def reset!
        @connection = nil
      end

      private

      def connection
        options = {
          url: SurveyGizmo.configuration.api_url,
          params: {
            api_token: SurveyGizmo.configuration.api_token,
            api_token_secret: SurveyGizmo.configuration.api_token_secret
          },
          request: {
            timeout: SurveyGizmo.configuration.timeout_seconds,
            open_timeout: SurveyGizmo.configuration.timeout_seconds
          }
        }

        retry_options = {
          max: SurveyGizmo.configuration.retry_attempts,
          interval: SurveyGizmo.configuration.retry_interval,
          exceptions: [
            BadResponseError,
            RateLimitExceededError,
            Errno::ETIMEDOUT,
            'Timeout::Error',
            'Error::TimeoutError'
          ]
        }

        @connection ||= Faraday.new(options) do |connection|
          connection.request :retry, retry_options
          connection.request :url_encoded

          connection.response :parse_survey_gizmo_data
          connection.response :pester_survey_gizmo
          connection.response :logger, SurveyGizmo.configuration.logger, bodies: true if SurveyGizmo.configuration.api_debug
          connection.response :json, content_type: /\bjson$/

          connection.adapter Faraday.default_adapter
        end
      end
    end
  end
end
