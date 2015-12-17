module SurveyGizmo
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration) if block_given?
    SurveyGizmo.setup
  end

  def self.reset!
    self.configuration = Configuration.new
  end

  class Configuration
    DEFAULT_RESULTS_PER_PAGE = 50
    DEFAULT_API_VERSION = 'v4'

    attr_accessor :api_version
    attr_accessor :user
    attr_accessor :password
    attr_accessor :results_per_page

    def initialize
      # Warning: SG sometimes times out if you request many results per page.
      # Saw a lot of timeouts with responses at 250 though the theoretical maximum is 500.
      @results_per_page = DEFAULT_RESULTS_PER_PAGE
      @api_version = DEFAULT_API_VERSION
    end
  end
end
