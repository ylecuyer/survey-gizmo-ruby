module SurveyGizmo; module API
  # @see SurveyGizmo::Resource::ClassMethods
  class Option
    include SurveyGizmo::Resource

    attribute :id,            Integer
    attribute :survey_id,     Integer
    attribute :page_id,       Integer
    attribute :question_id,   Integer
    attribute :title,         String
    attribute :value,         String
    attribute :properties,    Hash

    include SurveyGizmo::MultilingualTitle

    route '/survey/:survey_id/surveypage/:page_id/surveyquestion/:question_id/surveyoption',     via: :create
    route '/survey/:survey_id/surveypage/:page_id/surveyquestion/:question_id/surveyoption/:id', via: [:get, :update, :delete]

    def to_param_options
      { id: self.id, survey_id: self.survey_id, page_id: self.page_id, question_id: self.question_id }
    end
  end
end; end