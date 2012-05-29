module SurveyGizmo; module API
  # @see SurveyGizmo::Resource::ClassMethods
  class Response
    include SurveyGizmo::Resource

    # @macro [attach] virtus_attribute
    #   @return [$2] the attribute +$1+ as a $2
    attribute :id,             Integer
    attribute :data,           String
    attribute :status,         String
    attribute :survey_id,      Integer
    attribute :contact_id,     Integer
    attribute :date_submitted, DateTime
    attribute :is_test_data,   Boolean

    # routing
    route '/survey/:survey_id/surveyresponse',     :via => :create
    route '/survey/:survey_id/surveyresponse/:id', :via => [:get, :update, :delete]

    # @see SurveyGizmo::Resource#to_param_options
    def to_param_options
      {:id => self.id, :survey_id => self.survey_id}
    end

  end
end; end