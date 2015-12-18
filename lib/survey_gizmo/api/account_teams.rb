# This REST endpoint is only available to accounts with admin privileges
# This code is untested.

module SurveyGizmo
  module API
    class AccountTeams
      include SurveyGizmo::Resource

      attribute :id,            Integer
      attribute :teamid,        Integer
      attribute :teamname,      String
      attribute :color,         String
      attribute :default_role,  String
      attribute :status,        String

      route '/accountteams/:id', [:get, :update, :delete]
      route '/accountteams',     :create

      def to_param_options
        { id: id }
      end
    end
  end
end
