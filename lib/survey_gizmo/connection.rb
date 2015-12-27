require 'active_support/core_ext/module/delegation'

module SurveyGizmo
  class Connection
    TIMEOUT_SECONDS = 300

    class << self
      delegate :put, :get, :delete, :post, to: :connection

      def reset!
        @connection = nil
      end

      private

      def connection
        fail 'Not configured' unless SurveyGizmo.configuration

        options = {
          url: SurveyGizmo.configuration.api_url,
          params: { 'user:md5' => "#{SurveyGizmo.configuration.user}:#{Digest::MD5.hexdigest(SurveyGizmo.configuration.password)}" },
          request: {
            timeout: TIMEOUT_SECONDS,
            open_timeout: TIMEOUT_SECONDS
          }
        }

        @connection ||= Faraday.new(options) do |connection|
          connection.request :url_encoded

          connection.response :parse_survey_gizmo_data
          connection.response :pester_survey_gizmo
          connection.response :logger, @logger, bodies: true if SurveyGizmo.configuration.api_debug
          connection.response :json, content_type: /\bjson$/

          connection.adapter Faraday.default_adapter
        end
      end
    end
  end
end
