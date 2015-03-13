module SurveyGizmo; module API
  # @see SurveyGizmo::Resource::ClassMethods
  class Question
    include SurveyGizmo::Resource

    # @macro [attach] virtus_attribute
    #   @return [$2]
    attribute :id,                 Integer
    attribute :title,              String
    attribute :type,               String
    attribute :description,        String
    attribute :shortname,          String
    attribute :properties,         Hash
    attribute :after,              Integer
    attribute :survey_id,          Integer
    attribute :page_id,            Integer, :default => 1
    attribute :sub_question_skus,  Array
    attribute :parent_question_id, Integer

    alias_attribute :_subtype, :type

    route '/survey/:survey_id/surveyquestion/:id', via: :get
    route '/survey/:survey_id/surveypage/:page_id/surveyquestion', via: :create
    route '/survey/:survey_id/surveypage/:page_id/surveyquestion/:id', via: [:update, :delete]

    # @macro collection
    def options
      SurveyGizmo::API::Option.all(survey_id: survey_id, question_id: id)
    end

    # survey gizmo sends a hash back for :title
    # @private
    def title_with_multilingual=(val)
      self.title_without_multilingual = val.is_a?(Hash) ? val['English'] : val
    end

    alias_method_chain :title=, :multilingual

    # These are not returned by the .all request for a survey_id!
    def sub_questions
      return @sub_questions if @subquestions || sub_question_skus.nil?

      @sub_questions = []
      sub_question_skus.each do |sub_question_id|
        @sub_questions << SurveyGizmo::API::Question.first(survey_id: survey_id, id: sub_question_id)
      end
      @sub_questions
    end

    # @see SurveyGizmo::Resource#to_param_options
    def to_param_options
      {id: self.id, survey_id: self.survey_id, page_id: self.page_id}
    end
  end
end; end
