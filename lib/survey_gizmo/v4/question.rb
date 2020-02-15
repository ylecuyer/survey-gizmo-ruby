require 'survey_gizmo/v4/option'

module SurveyGizmo::V4
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

    # v4 fields
    attribute :after,              Integer
    attribute :sub_questions_skus, Array
    
    alias_attribute :_subtype, :type

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

    def sub_question_skus
      # As of 2015-12-23, the sub_question_skus attribute can either contain an array of integers if no shortname (alias)
      # was set for any question, or an array of [String, Integer] with the String corresponding to the subquestion
      # shortname and the integer corresponding to the subquestion id if at least one shortname was set.
      @sub_question_skus.map { |sku| sku.is_a?(Array) ? sku[1] : sku }
    end

    def sub_questions
      @sub_questions ||= sub_question_skus.map do |sku|
        SurveyGizmo.configuration.logger.debug("Have to do individual load of sub question #{sku}...")
        subquestion = Question.first(survey_id: survey_id, id: sku)
        subquestion.parent_question_id = id
        subquestion
      end
    end
  end
end
