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
      @questions ||= Question.all(children_params.merge(all_pages: true)).to_a

      # See note about broken subquestions in resource.rb
      @questions.flat_map { |q| q.sub_question_skus }.each do |sku|
        next if @questions.find { |q| q.id == sku }
        @questions << Question.first(survey_id: survey_id, id: sku)
      end

      @questions.each { |q| q.attributes = children_params }
    end

    def to_param_options
      { id: id, survey_id: survey_id }
    end
  end
end; end
