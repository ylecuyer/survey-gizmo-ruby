module SurveyGizmo; module API
  # @see SurveyGizmo::Resource::ClassMethods
  class SurveyCampaign
    include SurveyGizmo::Resource

    # @macro [attach] virtus_attribute
    #   @return [$2]
    attribute :id,            Integer
    attribute :name,          String
    attribute :type,          String
    attribute :status,        String
    attribute :slug,          String
    attribute :language,      String
    attribute :survey_id,     Integer

    alias_attribute :_subtype, :type

    route '/survey/:survey_id/surveycampaign/:id', :via => :get
    route '/survey/:survey_id/surveycampaign/:id', :via => :create
    route '/survey/:survey_id/surveycampaign/:id', :via => [:update, :delete]

    # @macro collection
    collection :options

    # @see SurveyGizmo::Resource#to_param_options
    def to_param_options
      {:id => self.id, :survey_id => self.survey_id}
    end
  end
end; end