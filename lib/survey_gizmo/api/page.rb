module SurveyGizmo; module API
  # @see SurveyGizmo::Resource::ClassMethods
  class Page
    include SurveyGizmo::Resource

    attribute :id,            Integer
    attribute :title,         Hash
    attribute :description,   String
    attribute :properties,    Hash
    attribute :after,         Integer
    attribute :survey_id,     Integer

    # routing
    route '/survey/:survey_id/surveypage', :via => :create
    route '/survey/:survey_id/surveypage/:id', :via => [:get, :update, :delete]

    def survey
      @survey ||= SurveyGizmo::API::Survey.first(id: survey_id)
    end

    def questions
      @questions ||= SurveyGizmo::API::Question.all(survey_id: survey_id, page_id: id)
    end

    # survey gizmo sends a hash back for :title
    def title_with_multilingual=(val)
      self.title_without_multilingual = val.is_a?(Hash) ? val : { 'English' => val }
    end

    alias_method_chain :title=, :multilingual

    def to_param_options
      { id: self.id, survey_id: self.survey_id }
    end
  end
end; end
