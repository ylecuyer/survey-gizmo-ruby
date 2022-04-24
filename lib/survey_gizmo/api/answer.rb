module SurveyGizmo::API
  class Answer
    include Virtus.model

    attribute :key,           String
    attribute :value,         String
    attribute :survey_id,     Integer
    attribute :response_id,   Integer
    attribute :question_id,   Integer
    attribute :option_id,     Integer
    attribute :submitted_at,  DateTime
    attribute :answer_text,   String
    attribute :other_text,    String
    attribute :question_pipe, String

    def initialize(attrs = {})
      self.attributes = attrs

      case key
      when /\[question\((\d+)\),\s*option\((\d+|"\d+-other")\)\]/
        self.question_id, self.option_id = $1, $2

        if option_id.to_s =~ /-other/
          option_id.delete!('-other"')
          self.other_text = value
        elsif option_id == 0
          # Option IDs of 0 seem to happen for hidden questions, even when there is answer_text
          self.option_id = nil
        end
      when /\[question\((\d+)\),\s*question_pipe\("?(.*)"?\)\]/
        self.question_id, self.question_pipe = $1, $2

#        question_pipe.slice!(0) if question_pipe.starts_with?('"')
        question_pipe.chop! if question_pipe.ends_with?('"')

      when /\[question\((\d+)\)\]/
        self.question_id = $1
      else
        fail "Can't recognize pattern for #{attrs[:key]} => #{attrs[:value]} - you may have to parse your answers manually."
      end

      self.question_id = question_id.to_i

      if option_id && !option_id.is_a?(Integer)
        fail "Bad option_id #{option_id} (class: #{option_id.class}) for #{attrs}!" if option_id.to_i == 0
        self.option_id = option_id.to_i
      end
    end

    # Strips out the answer_text when there is a valid option_id
    def to_hash
      {
        response_id: response_id,
        question_id: question_id,
        option_id: option_id,
        question_pipe: question_pipe,
        submitted_at: submitted_at,
        survey_id: survey_id,
        other_text: other_text,
        answer_text: option_id || other_text ? nil : answer_text
      }.reject { |k, v| v.nil? }
    end
  end
end
