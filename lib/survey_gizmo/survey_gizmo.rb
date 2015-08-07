module SurveyGizmo
  include HTTParty
  debug_output $stderr if ENV['GIZMO_DEBUG']
  default_timeout 600  # 10 minutes, SurveyGizmo has serious problems.

  format :json

  URLError = Class.new(RuntimeError)

  # Setup the account credentials to access the API
  # @param [Hash] opts
  # @option opts [#to_s] :user
  #   The username for your account. Usually your email address
  # @option opts [#to_s] :password
  #   The account password
  def self.setup
    base_uri "https://restapi.surveygizmo.com/#{SurveyGizmo.configuration.api_version}"
    default_params({ 'user:md5' => "#{SurveyGizmo.configuration.user}:#{Digest::MD5.hexdigest(SurveyGizmo.configuration.password)}" })
  end
end
