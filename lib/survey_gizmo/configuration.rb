require 'survey_gizmo/faraday_middleware/parse_survey_gizmo'

module SurveyGizmo

  CONFIG_THREAD_VARIABLE_NAME = :survey_gizmo_configuration

  class << self
    def configuration
      fail 'Not configured!' unless Thread.current[CONFIG_THREAD_VARIABLE_NAME] || @global_config
      Thread.current[CONFIG_THREAD_VARIABLE_NAME] ||= @global_config.dup
    end

    def configuration=(new_config)
      @global_config = new_config.dup
      Thread.current[CONFIG_THREAD_VARIABLE_NAME] = new_config
    end

    def configure
      reset!
      yield(configuration) if block_given?

      if configuration.retry_attempts
        configuration.logger.warn('Configuring retry_attempts is deprecated; pass a retriable_params hash instead.')
        configuration.retriable_params[:tries] = configuration.retry_attempts + 1
      end

      if configuration.retry_interval
        configuration.logger.warn('Configuring retry_interval is deprecated; pass a retriable_params hash instead.')
        configuration.retriable_params[:base_interval] = configuration.retry_interval
      end

      configuration.retriable_params = Configuration::DEFAULT_RETRIABLE_PARAMS.merge(configuration.retriable_params)

      @global_config = configuration
    end

    def reset!
      Thread.current[CONFIG_THREAD_VARIABLE_NAME] = Configuration.new
      Connection.reset!
    end
  end

  class Configuration
    DEFAULT_API = :surveygizmo
    DEFAULT_API_VERSION = 'v4'.freeze
    DEFAULT_RESULTS_PER_PAGE = 50
    DEFAULT_TIMEOUT_SECONDS = 300
    DEFAULT_REGION = :us
    DEFAULT_LOCALE = 'English'.freeze

    APIS_INFO = {
      surveygizmo: 'restapi.surveygizmo',
      alchemer: 'api.alchemer'
    }.freeze

    REGION_INFO = {
      us: {
        tld: 'com',
        locale: 'Eastern Time (US & Canada)'
      },
      eu: {
        tld: 'eu',
        locale: 'UTC'
      }
    }.freeze

    DEFAULT_RETRIABLE_PARAMS = {
      base_interval: 60,
      max_interval: 300,
      rand_factor: 0,
      tries: 4,
      on: [
        Errno::ETIMEDOUT,
        Faraday::ClientError,
        Net::ReadTimeout,
        SurveyGizmo::BadResponseError,
        SurveyGizmo::RateLimitExceededError
      ],
      on_retry: Proc.new do |exception, tries|
        SurveyGizmo.configuration.logger.warn("Retrying after #{exception.class}: #{tries} attempts.")
      end
    }.freeze

    attr_accessor :api_token
    attr_accessor :api_token_secret

    attr_accessor :api_debug
    attr_accessor :api_url
    attr_accessor :api_time_zone
    attr_accessor :api_version
    attr_accessor :logger
    attr_accessor :results_per_page
    attr_accessor :timeout_seconds
    attr_accessor :retriable_params
    attr_accessor :locale
    # TODO Deprecated; remove in 7.0
    attr_accessor :retry_attempts
    attr_accessor :retry_interval

    def initialize
      @api_token = ENV['SURVEYGIZMO_API_TOKEN'] || nil
      @api_token_secret = ENV['SURVEYGIZMO_API_TOKEN_SECRET'] || nil

      @api_version = DEFAULT_API_VERSION
      @results_per_page = DEFAULT_RESULTS_PER_PAGE
      @timeout_seconds = DEFAULT_TIMEOUT_SECONDS
      @retriable_params = DEFAULT_RETRIABLE_PARAMS
      @locale = DEFAULT_LOCALE
      self.api = DEFAULT_API
      self.region = DEFAULT_REGION

      @logger = SurveyGizmo::Logger.new(STDOUT)
      @api_debug = ENV['GIZMO_DEBUG'].to_s =~ /^(true|t|yes|y|1)$/i
    end

    def region=(region)
      region_infos = REGION_INFO[region]
      raise ArgumentError.new("Unknown region: #{region}") unless region_infos

      @api_tld = region_infos[:tld]
      @api_time_zone = region_infos[:locale]

      build_api_url
    end

    def api=(api)
      raise ArgumentError.new("Unknown api: #{api}") unless APIS_INFO.keys.include?(api)

      @api = APIS_INFO[api]

      build_api_url
    end

    private

    def build_api_url
      @api_url = "https://#{@api}.#{@api_tld}"
    end
  end
end
