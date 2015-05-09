module SurveyGizmo;
  module API
  # @see SurveyGizmo::Resource::ClassMethods
    class AccountTeams
      include SurveyGizmo::Resource

      # @macro [attach] virtus_attribute
      #   @return [$2]
      attribute :id, Integer
      attribute :teamid,        Integer
      attribute :teamname,      String
      attribute :color,          String
      attribute :default_role,   String
      attribute :status,         String

      route '/accountteams/:id', via: [:get, :update, :delete]
      route '/accountteams',     via: :create

      # @see SurveyGizmo::Resource#to_param_options
      def to_param_options
        { id: self.id }
      end
    end
  end
end
