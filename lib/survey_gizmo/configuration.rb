module SurveyGizmo
  class << self
    attr_writer :configuration

    def configuration
      fail 'Not configured!' unless @configuration
      @configuration
    end

    def configure
      @configuration ||= Configuration.new
      yield(configuration) if block_given?
    end

    def reset!
      self.configuration = Configuration.new
      Connection.reset!
    end

    private

    def retryables
      [
        Net::ReadTimeout,
        Faraday::Error::TimeoutError,
        SurveyGizmo::RateLimitExceededError
      ]
    end
  end

  class Configuration
    DEFAULT_REST_API_URL = 'https://restapi.surveygizmo.com'
    DEFAULT_API_VERSION = 'v4'
    DEFAULT_RESULTS_PER_PAGE = 50
    DEFAULT_TIMEOUT_SECONDS = 300
    DEFAULT_RETRIES = 3
    DEFAULT_RETRY_INTERVAL = 60

    attr_accessor :api_token
    attr_accessor :api_token_secret

    attr_accessor :api_debug
    attr_accessor :api_url
    attr_accessor :api_version
    attr_accessor :logger
    attr_accessor :results_per_page

    attr_accessor :timeout_seconds
    attr_accessor :retry_attempts
    attr_accessor :retry_interval


    def initialize
      @api_token = ENV['SURVEYGIZMO_API_TOKEN'] || nil
      @api_token_secret = ENV['SURVEYGIZMO_API_TOKEN_SECRET'] || nil

      @api_url = DEFAULT_REST_API_URL
      @api_version = DEFAULT_API_VERSION
      @results_per_page = DEFAULT_RESULTS_PER_PAGE

      @timeout_seconds = DEFAULT_TIMEOUT_SECONDS
      @retry_attempts = DEFAULT_RETRIES
      @retry_interval = DEFAULT_RETRY_INTERVAL

      @logger = SurveyGizmo::Logger.new(STDOUT)
      @api_debug = ENV['GIZMO_DEBUG'].to_s =~ /^(true|t|yes|y|1)$/i
    end
  end
end
