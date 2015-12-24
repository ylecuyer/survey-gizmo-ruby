module SurveyGizmo
  class Connection
    include Singleton
    extend Forwardable

    TIMEOUT_SECONDS = 300

    def_delegators :connection, :get, :put, :delete, :post

    class PesterMiddleware < Faraday::Middleware
      Faraday::Response.register_middleware(pester: self)

      def call(environment)
        Pester.survey_gizmo_ruby.retry { @app.call(environment) }
      end
    end

    def reset!
      @connection = nil
    end

    def api_debug?
      ENV['GIZMO_DEBUG'].to_s =~ /^(true|t|yes|y|1)$/i
    end

    private

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
        connection.response :logger, @logger, bodies: true if api_debug?
        connection.response :json, content_type: /\bjson$/

        connection.adapter Faraday.default_adapter
      end
    end
  end
end
