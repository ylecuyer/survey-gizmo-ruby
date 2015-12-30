require 'survey_gizmo/api/question'

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
    attribute :questions,     Array[Question]

    @route = '/survey/:survey_id/surveypage'

    def survey
      @survey ||= Survey.first(id: survey_id)
    end

    def questions
      # See note about broken subquestions in resource.rb
      @questions.flat_map { |q| q.sub_question_skus }.each do |sku|
        sku = sku[1] if sku.is_a?(Array)
        next if @questions.find { |q| q.id == sku }
        @questions << Question.first(children_params.merge(id: sku))
      end

      @questions.each { |q| q.attributes = children_params }
    end
  end
end; end
