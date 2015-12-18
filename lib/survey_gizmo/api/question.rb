module SurveyGizmo; module API
  # @see SurveyGizmo::Resource::ClassMethods
  class Question
    include SurveyGizmo::Resource
    include SurveyGizmo::MultilingualTitle

    attribute :id,                 Integer
    attribute :type,               String
    attribute :description,        String
    attribute :shortname,          String
    attribute :properties,         Hash
    attribute :after,              Integer
    attribute :survey_id,          Integer
    attribute :page_id,            Integer, default: 1
    attribute :sub_question_skus,  Array
    attribute :parent_question_id, Integer

    alias_attribute :_subtype, :type

    route '/survey/:survey_id/surveyquestion/:id', via: :get
    route '/survey/:survey_id/surveypage/:page_id/surveyquestion', via: :create
    route '/survey/:survey_id/surveypage/:page_id/surveyquestion/:id', via: [:update, :delete]

    def survey
      @survey ||= Survey.first(id: survey_id)
    end

    def options
      @options ||= Option.all(survey_id: survey_id, page_id: page_id, question_id: id, all_pages: true)
    end

    def parent_question
      @parent_question ||= parent_question_id ? Question.first(survey_id: survey_id, id: parent_question_id) : nil
    end

    def sub_questions
      @sub_questions ||= sub_question_skus.map { |subquestion_id| Question.first(survey_id: survey_id, id: subquestion_id) }
                                          .each { |subquestion| subquestion.parent_question_id = id  }
    end

    # @see SurveyGizmo::Resource#to_param_options
    def to_param_options
      { id: self.id, survey_id: self.survey_id, page_id: self.page_id }
    end
  end
end; end
