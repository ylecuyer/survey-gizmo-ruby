module SurveyGizmo
  class Connection
    include Singleton
    extend Forwardable

    TIMEOUT_SECONDS = 300

    def_delegators :connection, :get, :put, :delete, :post

    def reset!
      @connection = nil
    end

    private

    class PesterMiddleware < Faraday::Middleware
      Faraday::Response.register_middleware(pester: self)

      def call(environment)
        Pester.survey_gizmo_ruby.retry do
          @app.call(environment).on_complete do |response_env|
            fail RateLimitExceededError if response_env.status == 429
            fail "Bad response code #{http_response.status} in #{http_response.inspect}" unless response_env.status == 200
            fail BadResponseError, response_env.inspect unless response_ok?(response_env)
          end
        end
      end

      private

      def response_ok?(response)
        response.body['result_ok'] && response.body['result_ok'].to_s.downcase == 'true'
      end
    end

    def connection
      fail 'Not configured' unless SurveyGizmo.configuration

      options = {
        url: "https://restapi.surveygizmo.com",
        params: { 'user:md5' => "#{SurveyGizmo.configuration.user}:#{Digest::MD5.hexdigest(SurveyGizmo.configuration.password)}" },
        request: {
          timeout: TIMEOUT_SECONDS,
          open_timeout: TIMEOUT_SECONDS
        }
      }

      @connection ||= Faraday.new(options) do |connection|
        connection.request :url_encoded

        connection.response :pester
        connection.response :logger, @logger, bodies: true if SurveyGizmo.configuration.api_debug
        connection.response :json, content_type: /\bjson$/

        connection.adapter Faraday.default_adapter
      end
    end
  end
end
