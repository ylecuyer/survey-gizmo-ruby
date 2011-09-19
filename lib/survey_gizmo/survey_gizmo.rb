require "active_support/core_ext"
require "active_support/concern"
require "virtus"
require "httparty"

module SurveyGizmo
  include HTTParty
  
  base_uri 'https://restapi.surveygizmo.com/v1/survey'
  @@options = {}
  mattr_accessor :options
  
  def self.setup(opts = {})
    self.options = opts
  end
  
  def self.auth_params
    {"user:pass" => self.options.values_at(:user, :password).join(':')}
  end
  
  module API
    ROOT = File.expand_path(File.dirname(__FILE__))
    autoload :Survey,   "#{ROOT}/api/survey"
  end
end