module SurveyGizmo
  class PesterSurveyGizmoMiddleware < Faraday::Middleware
    Faraday::Response.register_middleware(pester_survey_gizmo: self)

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
