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
      Pester.configure { |c| c.environments[:survey_gizmo_ruby] = nil }
      configure_pester
      Connection.reset!
    end

    private

    def configure_pester
      default_config = {
        on_retry: Pester::Behaviors::Sleep::Constant,
        logger: configuration.logger,
        max_attempts: 2,
        delay_interval: 60,
        retry_error_classes: retryables
      }

      Pester.configure do |c|
        if c.environments[:survey_gizmo_ruby].nil?
          c.environments[:survey_gizmo_ruby] = default_config
        else
          c.environments[:survey_gizmo_ruby][:max_attempts] ||= default_config[:max_attempts]
          c.environments[:survey_gizmo_ruby][:delay_interval] ||= default_config[:delay_interval]

          # Don't set :retry_error_classes to something when user has configured nothing
          if c.environments[:survey_gizmo_ruby][:retry_error_classes].nil? && !c.environments[:survey_gizmo_ruby].has_key?(:retry_error_classes)
            c.environments[:survey_gizmo_ruby][:retry_error_classes] = retryables
          end
        end
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
