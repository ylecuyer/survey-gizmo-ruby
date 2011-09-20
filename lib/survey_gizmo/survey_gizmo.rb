require "active_support/core_ext/string"
require "active_support/core_ext/module"
require "active_support/core_ext/hash"
require "active_support/core_ext/object/blank"
require "active_support/concern"
require "virtus"
require "httparty"
require "survey_gizmo/resource"

module SurveyGizmo
  include HTTParty
  
  format :json
  base_uri 'https://restapi.surveygizmo.com/v1'
  @@options = {}
  mattr_accessor :options
  
  def self.setup(opts = {})
    self.options = opts
    default_params({"user:pass" => opts.values_at(:user, :password).join(':')})
  end
  
  module API
    ROOT = File.expand_path(File.dirname(__FILE__))
    autoload :Survey,   "#{ROOT}/api/survey"
    autoload :Question, "#{ROOT}/api/question"
  end
  
  
end