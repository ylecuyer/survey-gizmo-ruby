# This REST endpoint is only available to accounts with admin privileges
# This code is untested.

module SurveyGizmo::V5
  class AccountTeams
    include SurveyGizmo::Resource

    attribute :id,            Integer
    attribute :default_role,  String
    attribute :status,        String

    # v5 fields
    attribute :team_name,      String
    attribute :description,   String

    @route = '/accountteams'
  end
end
