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

    @route = '/survey/:survey_id/surveypage'

    def survey
      @survey ||= Survey.first(id: survey_id)
    end

    def questions
      @questions ||= Question.all(survey_id: survey_id, page_id: id, all_pages: true).to_a
    end

    def to_param_options
      { id: id, survey_id: survey_id }
    end
  end
end; end
