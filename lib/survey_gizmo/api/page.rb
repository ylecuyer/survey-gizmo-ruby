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
    route '/survey/:survey_id/surveypage', :create
    route '/survey/:survey_id/surveypage/:id', [:get, :update, :delete]

    def survey
      @survey ||= Survey.first(id: survey_id)
    end

    def questions
      @questions ||= Question.all(survey_id: survey_id, page_id: id, all_pages: true)
    end

    def to_param_options
      { id: id, survey_id: survey_id }
    end
  end
end; end
