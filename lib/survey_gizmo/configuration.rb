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
    DEFAULT_API_VERSION = 'v4'
    DEFAULT_RESULTS_PER_PAGE = 250

    attr_accessor :api_version
    attr_accessor :user
    attr_accessor :password
    attr_accessor :results_per_page

    def initialize
      @api_version = DEFAULT_API_VERSION
      @results_per_page = DEFAULT_RESULTS_PER_PAGE
    end
  end
end
