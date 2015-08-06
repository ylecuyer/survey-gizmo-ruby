require 'active_support/core_ext/string'
require 'active_support/core_ext/module'
require 'active_support/core_ext/hash'
require 'active_support/core_ext/object/blank'
require 'active_support/concern'
require 'awesome_print'
require 'virtus'
require 'httparty'
require 'digest/md5'


require 'survey_gizmo/resource'
require 'survey_gizmo/rest_response'

require 'survey_gizmo/api/account_teams'
require 'survey_gizmo/api/contact'
require 'survey_gizmo/api/email_message'
require 'survey_gizmo/api/option'
require 'survey_gizmo/api/page'
require 'survey_gizmo/api/question'
require 'survey_gizmo/api/response'
require 'survey_gizmo/api/survey'
require 'survey_gizmo/api/survey_campaign'

module SurveyGizmo
  include HTTParty
  debug_output $stderr if ENV['GIZMO_DEBUG']
  default_timeout 600  # 10 minutes, SurveyGizmo has serious problems.

  format :json

  URLError = Class.new(RuntimeError)

  # The base uri for this version of the API is $1
  base_uri 'https://restapi.surveygizmo.com/v4'

  @@options = {}
  mattr_accessor :options

  # Setup the account credentials to access the API
  # @param [Hash] opts
  # @option opts [#to_s] :user
  #   The username for your account. Usually your email address
  # @option opts [#to_s] :password
  #   The account password
  def self.setup(opts = {})
    self.options = opts
    default_params({ 'user:md5' => "#{opts[:user]}:#{Digest::MD5.hexdigest(opts[:password])}" })
  end

  def self.reset
    @@options = {}
    default_params({})
  end
end
