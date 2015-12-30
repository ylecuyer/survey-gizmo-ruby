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
      configure_pester
    end

    def reset!
      self.configuration = Configuration.new
      configure_pester
      Connection.reset!
    end

    private

    def configure_pester
      Pester.configure do |c|
        c.environments[:survey_gizmo_ruby] = {
          on_retry: Pester::Behaviors::Sleep::Constant,
          logger: configuration.logger
        }
        c.environments[:survey_gizmo_ruby][:max_attempts] ||= 2
        c.environments[:survey_gizmo_ruby][:delay_interval] ||= 60
        c.environments[:survey_gizmo_ruby][:retry_error_classes] ||= retryables
      end
    end

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

    attr_accessor :user
    attr_accessor :password

    attr_accessor :api_debug
    attr_accessor :api_url
    attr_accessor :api_version
    attr_accessor :logger
    attr_accessor :results_per_page

    def initialize
      @api_url = DEFAULT_REST_API_URL
      @api_version = DEFAULT_API_VERSION
      @results_per_page = DEFAULT_RESULTS_PER_PAGE
      @logger = ::Logger.new(STDOUT)
      @api_debug = ENV['GIZMO_DEBUG'].to_s =~ /^(true|t|yes|y|1)$/i
    end
  end
end
