module SurveyGizmo
  include HTTParty

  debug_output $stderr if ENV['GIZMO_DEBUG'] =~ /^(true|t|yes|y|1)$/i
  default_timeout 600  # 10 minutes, SurveyGizmo has serious problems.

  format :json

  class URLError < RuntimeError; end
  class RateLimitExceededError < RuntimeError; end
  class BadResponseError < RuntimeError; end

  def self.setup
    base_uri "https://restapi.surveygizmo.com/#{SurveyGizmo.configuration.api_version}"
    default_params({ 'user:md5' => "#{SurveyGizmo.configuration.user}:#{Digest::MD5.hexdigest(SurveyGizmo.configuration.password)}" })
  end
end
