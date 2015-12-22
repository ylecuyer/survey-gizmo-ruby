module SurveyGizmo
  module API
    class Answer
      def self.parse_answer(key, value)
        return nil unless value

        case key
        when /\[question\((\d+)\),\s*option\((\d+)\)\]/
          {
            question_id: $1,
            option_id: $2,
            answer: value
          }
        when /\[question\((\d+)\),\s*option\("(\d+)-other"\)\]/
          {
            question_id: $1,
            option_id: $2,
            answer: value
          }
        when /\[question\((\d+)\)\]/
          {
            question_id: $1,
            answer: value
          }
        else
          fail "Didn't recognize pattern for #{key} => #{value}"
        end
      end
    end
  end
end
