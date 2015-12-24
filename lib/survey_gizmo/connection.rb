module SurveyGizmo
  class Connection
    include Singleton

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

    def get(route, query = {})
      puts "getting #{route}"
      Pester.survey_gizmo_ruby.retry { connection.get(route, query.merge(authentication_params)) }
    end

    def put(route, query = {})
      Pester.survey_gizmo_ruby.retry { connection.put(route, query.merge(authentication_params)) }
    end

    def delete(route)
      Pester.survey_gizmo_ruby.retry { connection.delete(route, authentication_params) }
    end

    private

    def api_route(route)
    end

    def connection
      fail 'Not configured' unless SurveyGizmo.configuration

      @connection ||= Faraday.new("https://restapi.surveygizmo.com") do |connection|
        connection.request :url_encoded

        connection.response :logger, @logger, bodies: true if api_debug?
        connection.response :json, content_type: /\bjson$/

        connection.adapter Faraday.default_adapter
      end
    end

    def api_debug?
      ENV['GIZMO_DEBUG'].to_s =~ /^(true|t|yes|y|1)$/i
    end

    def authentication_params
      { 'user:md5' => "#{SurveyGizmo.configuration.user}:#{Digest::MD5.hexdigest(SurveyGizmo.configuration.password)}" }
    end
  end
end
