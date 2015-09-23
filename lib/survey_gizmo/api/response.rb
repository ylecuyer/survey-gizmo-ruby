module SurveyGizmo; module API
  # @see SurveyGizmo::Resource::ClassMethods
  class Response
    include SurveyGizmo::Resource

    attribute :id,                   Integer
    attribute :survey_id,            Integer
    attribute :contact_id,           Integer
    attribute :data,                 String
    attribute :status,               String
    attribute :datesubmitted,        DateTime
    attribute :is_test_data,         Boolean
    attribute :sResponseComment,     String
    attribute :variable,             Hash       # READ-ONLY
    attribute :meta,                 Hash       # READ-ONLY
    attribute :shown,                Hash       # READ-ONLY
    attribute :url,                  Hash       # READ-ONLY
    attribute :answers,              Hash       # READ-ONLY

    # routing
    route '/survey/:survey_id/surveyresponse',     via: :create
    route '/survey/:survey_id/surveyresponse/:id', via: [:get, :update, :delete]

    def survey
      @survey ||= SurveyGizmo::API::Survey.first(id: survey_id)
    end

    def to_param_options
      { id: self.id, survey_id: self.survey_id }
    end
  end
end; end
