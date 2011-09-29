require "active_support/core_ext/string"
require "active_support/core_ext/module"
require "active_support/core_ext/hash"
require "active_support/core_ext/object/blank"
require "active_support/concern"
require "virtus"
require "httparty"

require "survey_gizmo/resource"
require "survey_gizmo/collection"

require "survey_gizmo/api/survey"
require "survey_gizmo/api/question"
require "survey_gizmo/api/option"
require "survey_gizmo/api/page"

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
  
end