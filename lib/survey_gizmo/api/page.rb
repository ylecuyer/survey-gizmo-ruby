module SurveyGizmo; module API
  # @see SurveyGizmo::Resource::ClassMethods
  class Page
    include SurveyGizmo::Resource
    include SurveyGizmo::MultilingualTitle

    attribute :id,            Integer
    attribute :description,   String
    attribute :properties,    Hash
    attribute :after,         Integer
    attribute :survey_id,     Integer

    # routing
    route '/survey/:survey_id/surveypage', via: :create
    route '/survey/:survey_id/surveypage/:id', via: [:get, :update, :delete]

    def survey
      @survey ||= SurveyGizmo::API::Survey.first(id: survey_id)
    end

    def questions
      @questions ||= SurveyGizmo::API::Question.all(survey_id: survey_id, page_id: id)
    end

    def to_param_options
      { id: self.id, survey_id: self.survey_id }
    end
  end
end; end
