require 'active_support/concern'
require 'active_support/core_ext/array'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/hash'
require 'active_support/core_ext/module'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/string'
require 'active_support/time_with_zone'

require 'awesome_print'
require 'digest/md5'
require 'faraday'
require 'faraday_middleware'
require 'logger'
require 'pester'
require 'virtus'

require 'survey_gizmo/version'
require 'survey_gizmo/configuration'
require 'survey_gizmo/connection'
require 'survey_gizmo/multilingual_title'
require 'survey_gizmo/resource'
require 'survey_gizmo/rest_response'

require 'survey_gizmo/api/account_teams'
require 'survey_gizmo/api/answer'
require 'survey_gizmo/api/contact'
require 'survey_gizmo/api/email_message'
require 'survey_gizmo/api/option'
require 'survey_gizmo/api/page'
require 'survey_gizmo/api/question'
require 'survey_gizmo/api/response'
require 'survey_gizmo/api/survey'
require 'survey_gizmo/api/survey_campaign'

module SurveyGizmo
  class URLError < RuntimeError; end
  class RateLimitExceededError < RuntimeError; end
  class BadResponseError < RuntimeError; end
end
