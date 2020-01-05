# This REST endpoint is only available to accounts with admin privileges
# This code is untested.

module SurveyGizmo::API
  class AccountTeams
    include SurveyGizmo::Resource

    attribute :id,            Integer
    attribute :teamname,      String
    attribute :default_role,  String
    attribute :status,        String

    # v4 fields
    attribute :teamid,      Integer
    attribute :color,       Integer

    # v5 fields
    attribute :description,   String

    @route = '/accountteams'
  end
end
