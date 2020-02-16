require 'survey_gizmo/v5/option'

module SurveyGizmo::V5
  class Answer
    include Virtus.model

    attribute :key,           String
    attribute :value,         String
    attribute :survey_id,     Integer
    attribute :response_id,   Integer
    attribute :question_id,   Integer
    attribute :question_text, String
    attribute :question_type, String
    attribute :options,       Array[Option]
    attribute :submitted_at,  DateTime
    attribute :answer_text,   String
    attribute :other_text,    String
    attribute :question_pipe, String

    def initialize(attrs = {})
      self.attributes = attrs
      self.question_id = value['id']
      self.question_text = value['question']
      self.question_type = value['type']

      if value['options']
        self.options = selected_options
      elsif value['answer_id']
        self.options = single_option
      else
        self.answer_text = value['answer']
      end
    end

    def single_option
      [
        Option.new(attributes.merge(
          id: value['answer_id'],
          value: value['answer'], 
          title: value['original_answer'] || value['answer']
        ))
      ]
    end

    def selected_options
      value['options'].values.reject { |opt| opt['answer'].nil? }.map do |opt|
        Option.new(attributes.merge(
          id: opt['id'],
          value: opt['answer'],
          title: opt['option']
        ))
      end
    end

    # Strips out the answer_text when there is a valid option_id
    def to_hash
      {
        response_id: response_id,
        question_id: question_id,
        question_type: question_type,
        question_text: question_text,
        options: options,
        question_pipe: question_pipe,
        submitted_at: submitted_at,
        survey_id: survey_id,
        other_text: other_text,
        answer_text: options || other_text ? nil : answer_text
      }.reject { |k, v| v.nil? }
    end
  end
end
