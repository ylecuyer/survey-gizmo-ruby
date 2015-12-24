module SurveyGizmo; module API
  # @see SurveyGizmo::Resource::ClassMethods
  class Option
    include SurveyGizmo::Resource
    include SurveyGizmo::MultilingualTitle

    attribute :id,            Integer
    attribute :survey_id,     Integer
    attribute :page_id,       Integer
    attribute :question_id,   Integer
    attribute :value,         String
    attribute :properties,    Hash

    @route = '/survey/:survey_id/surveypage/:page_id/surveyquestion/:question_id/surveyoption'

    def to_param_options
      { id: id, survey_id: survey_id, page_id: page_id, question_id: question_id }
    end
  end
end; end