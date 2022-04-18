require 'survey_gizmo/v5/option'

module SurveyGizmo::V5
  class Question
    include SurveyGizmo::Resource
    include SurveyGizmo::MultilingualTitle

    attribute :id,                 Integer
    attribute :type,               String
    attribute :description,        String
    attribute :shortname,          String
    attribute :properties,         Hash
    attribute :options,            Array[Option]
    attribute :survey_id,          Integer
    attribute :page_id,            Integer, default: 1
    attribute :parent_question_id, Integer

    # v5 fields
    attribute :base_type,          String
    attribute :subtype,            String
    attribute :varname,            Array
    attribute :has_showhide_deps,  Boolean
    attribute :comment,            Boolean
    attribute :sub_questions,      Array[Question]

    @route = {
      get:    '/survey/:survey_id/surveyquestion/:id',
      create: '/survey/:survey_id/surveypage/:page_id/surveyquestion',
      update: '/survey/:survey_id/surveypage/:page_id/surveyquestion/:id'
    }
    @route[:delete] = @route[:update]

    def survey
      @survey ||= Survey.first(id: survey_id)
    end

    def options
      return parent_question.options.dup.each { |o| o.question_id = id } if parent_question

      @options ||= Option.all(children_params.merge(all_pages: true)).to_a
      @options.each { |o| o.attributes = children_params }
    end

    def parent_question
      return nil unless parent_question_id

      @parent_question ||= Question.first(survey_id: survey_id, id: parent_question_id)
    end
  end
end
