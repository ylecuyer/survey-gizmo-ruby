module SurveyGizmo
  class Connection
    include Singleton
    extend Forwardable

    def_delegators :connection, :get, :put, :delete

    class PesterMiddleware < Faraday::Middleware
      Faraday::Response.register_middleware(pester: self)

      def call(environment)
        Pester.survey_gizmo_ruby.retry { @app.call(environment) }
      end
    end

    def reset!
      @connection = nil
    end

    def post(route, payload)
      Pester.survey_gizmo_ruby.retry do
        connection.post(route) do |request|
          request.body = { data: payload }.to_json
        end
      end
    end

    def api_debug?
      ENV['GIZMO_DEBUG'].to_s =~ /^(true|t|yes|y|1)$/i
    end

    private

    def api_route(route)
    end

    def connection
      fail 'Not configured' unless SurveyGizmo.configuration

      auth_params = { 'user:md5' => "#{SurveyGizmo.configuration.user}:#{Digest::MD5.hexdigest(SurveyGizmo.configuration.password)}" }
      @connection ||= Faraday.new(url: "https://restapi.surveygizmo.com", params: auth_params) do |connection|
        connection.request :url_encoded

        connection.response :pester
        connection.response :logger, @logger, bodies: true if api_debug?
        connection.response :json, content_type: /\bjson$/

        connection.adapter Faraday.default_adapter
      end
    end
  end
end
