require 'active_support/core_ext/module/delegation'

module SurveyGizmo
  class Connection
    class << self
      def get(route)
        Retriable.retriable(retriable_args) { connection.get(route) }
      end

      def post(route, params)
        Retriable.retriable(retriable_args) { connection.post(route, params) }
      end

      def put(route, params)
        Retriable.retriable(retriable_args) { connection.put(route, params) }
      end

      def delete(route)
        Retriable.retriable(retriable_args) { connection.delete(route) }
      end

      def reset!
        @connection = nil
      end

      private

      def connection
        faraday_options = {
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

        @connection ||= Faraday.new(faraday_options) do |connection|
          connection.request :url_encoded

          connection.response :parse_survey_gizmo_data
          connection.response :json, content_type: /\bjson$/
          connection.response :logger, SurveyGizmo.configuration.logger, bodies: true if SurveyGizmo.configuration.api_debug

          connection.adapter Faraday.default_adapter
        end
      end

      def retriable_args
        {
          interval: SurveyGizmo.configuration.retry_interval,
          tries: SurveyGizmo.configuration.retry_attempts + 1,
          on: [
            Errno::ETIMEDOUT,
            Faraday::Error::ClientError,
            Net::ReadTimeout,
            SurveyGizmo::BadResponseError,
            SurveyGizmo::RateLimitExceededError
          ],
          on_retry: Proc.new do |exception, tries|
            SurveyGizmo.configuration.logger.warn("Retrying after #{exception.class}: #{tries} attempts.")
          end
        }
      end
    end
  end
end
