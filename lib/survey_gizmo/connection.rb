require 'active_support/core_ext/module/delegation'

module SurveyGizmo
  class Connection
    class << self
      def get(route)
        Retriable.retriable(SurveyGizmo.configuration.retriable_params) { connection.get(route) }
      end

      def post(route, params)
        Retriable.retriable(SurveyGizmo.configuration.retriable_params) { connection.post(route, params) }
      end

      def put(route, params)
        Retriable.retriable(SurveyGizmo.configuration.retriable_params) { connection.put(route, params) }
      end

      def delete(route)
        Retriable.retriable(SurveyGizmo.configuration.retriable_params) { connection.delete(route) }
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
          puts connection
          puts connection.response
          connection.response :parse_survey_gizmo_data
          connection.response :json, content_type: /\bjson$/
          connection.response :logger, SurveyGizmo.configuration.logger, bodies: true if SurveyGizmo.configuration.api_debug

          connection.adapter Faraday.default_adapter
        end
      end
    end
  end
end
