module SurveyGizmo
  module API
    class Answer
      attr_accessor :raw_key
      attr_accessor :raw_value

      attr_accessor :survey_id
      attr_accessor :response_id
      attr_accessor :question_id
      attr_accessor :option_id
      attr_accessor :submitted_at
      attr_accessor :answer_text
      attr_accessor :other_text
      attr_accessor :question_pipe

      def initialize(survey_id, response_id, submitted_at, key, value)
        @survey_id = survey_id
        @response_id = response_id
        @raw_key = key
        @raw_value = value
        @answer_text = value

        case key
        when /\[question\((\d+)\),\s*option\((\d+|"\d+-other")\)\]/
          @question_id, @option_id = $1, $2

          if @option_id =~ /other/
            @option_id.delete!('-other"')
            @other_text = value
          end
        when /\[question\((\d+)\),\s*question_pipe\("(.*)"\)\]/
          @question_id = $1
          @question_pipe = $2
        when /\[question\((\d+)\)\]/
          @question_id = $1
        else
          fail "Didn't recognize pattern for #{key} => #{value} - you may have to parse your answers manually."
        end

        @question_id = @question_id.to_i
        if @option_id
          fail "Bad option_id #{@option_id}!" if @option_id.to_i == 0 && @option_id != '0'
          @option_id = @option_id.to_i
        end
      end

      # Strips out the answer_text when there is a valid option_id
      def to_hash
        {
          response_id: @response_id,
          question_id: @question_id,
          option_id: @option_id,
          question_pipe: @question_pipe,
          survey_id: @survey_id,
          other_text: @other_text,
          answer_text: @option_id || @other_text ? nil : @answer_text
        }.reject { |k,v| v.nil? }
      end
    end
  end
end
