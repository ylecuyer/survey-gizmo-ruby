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

      route '/accountteams/:id', via: [:get, :update, :delete]
      route '/accountteams',     via: :create

      def to_param_options
        { id: self.id }
      end
    end
  end
end
