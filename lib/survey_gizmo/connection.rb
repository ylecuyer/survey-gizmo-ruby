require 'active_support/core_ext/module/delegation'

module SurveyGizmo
  class RateLimitExceededError < RuntimeError; end
  class BadResponseError < RuntimeError; end

  class Connection
    include Singleton

    TIMEOUT_SECONDS = 300

    class << self
      delegate :put, :get, :delete, :post, to: :instance
    end
    delegate :put, :get, :delete, :post, to: :connection
#    def_delegators :connection, :get, :put, :delete, :post

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

        connection.response :pester
        connection.response :logger, @logger, bodies: true if SurveyGizmo.configuration.api_debug
        connection.response :json, content_type: /\bjson$/

        connection.adapter Faraday.default_adapter
      end
    end

    class PesterMiddleware < Faraday::Middleware
      Faraday::Response.register_middleware(pester: self)

      def call(environment)
        Pester.survey_gizmo_ruby.retry do
          @app.call(environment).on_complete do |response|
            fail RateLimitExceededError if response.status == 429
            fail BadResponseError, "Bad response code #{response.status} in #{response.inspect}" unless response.status == 200
            unless response.body['result_ok'] && response.body['result_ok'].to_s.downcase == 'true'
              fail BadResponseError, response.inspect unless response_ok?(response)
            end
          end
        end
      end
    end
  end
end
