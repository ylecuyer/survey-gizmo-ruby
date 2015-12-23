module SurveyGizmo
  module API
    class Answer
      attr_accessor :raw_key
      attr_accessor :raw_value

      attr_accessor :survey_id
      attr_accessor :question_id
      attr_accessor :option_id
      attr_accessor :answer_text
      attr_accessor :other_text
      attr_accessor :question_pipe

      def initialize(survey_id, key, value)
        @survey_id = survey_id
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
          @question_id = $1.to_i
          @question_pipe = $2
        when /\[question\((\d+)\)\]/
          @question_id = $1.to_i
        else
          fail "Didn't recognize pattern for #{key} => #{value} - you may have to parse your answers manually."
        end

        @question_id = @question_id.to_i
        @option_id = @option_id.to_i if @option_id
      end

      def to_hash
        base = { question_id: @question_id, option_id: @option_id, question_pipe: @question_pipe, survey_id: @survey_id }
        @other_text ? base[:other_text] = @other_text : base[:answer_text] = @answer_text
        base.reject { |k,v| v.nil? }
      end
    end
  end
end
