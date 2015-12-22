module SurveyGizmo; module API
  # @see SurveyGizmo::Resource::ClassMethods
  class Response
    include SurveyGizmo::Resource

    # Filters
    NO_TEST_DATA =   { field: 'istestdata', operator: '<>', value: 1 }
    ONLY_COMPLETED = { field: 'status',     operator: '=',  value: 'Complete' }

    def self.submitted_since_filter(time)
      {
        field: 'datesubmitted',
        operator: '>=',
        value: time.in_time_zone('Eastern Time (US & Canada)').strftime('%Y-%m-%d %H:%M:%S')
      }
    end

    attribute :id,                   Integer
    attribute :survey_id,            Integer
    attribute :contact_id,           Integer
    attribute :data,                 String
    attribute :status,               String
    attribute :datesubmitted,        DateTime
    attribute :is_test_data,         Boolean
    attribute :sResponseComment,     String
    attribute :variable,             Hash       # READ-ONLY
    attribute :meta,                 Hash       # READ-ONLY
    attribute :shown,                Hash       # READ-ONLY
    attribute :url,                  Hash       # READ-ONLY
    attribute :answers,              Hash       # READ-ONLY

    route '/survey/:survey_id/surveyresponse',     :create
    route '/survey/:survey_id/surveyresponse/:id', [:get, :update, :delete]

    def survey
      @survey ||= Survey.first(id: survey_id)
    end

    def parsed_answers
      answers.select do |k,v|
        next false unless v.is_a?(FalseClass) || v

        if k =~ /\[question\((\d+)\),\s*option\((\d+)\)\]/
          # Strip out "Other" answers that don't actually have the "other" text
          !answers.keys.any? { |key| key =~ /\[question\((#{$1})\),\s*option\("(#{$2})-other"\)\]/ }
        else
          true
        end
      end.map { |k,v| parse_answer(k, v) }
    end

    def to_param_options
      { id: id, survey_id: survey_id }
    end

    private

    def parse_answer(key, value)
      case key
      when /\[question\((\d+)\),\s*option\((\d+)\)\]/
        {
          question_id: $1.to_i,
          option_id: $2.to_i,
          answer_text: value
        }
      when /\[question\((\d+)\),\s*option\("(\d+)-other"\)\]/
        {
          question_id: $1.to_i,
          option_id: $2.to_i,
          answer_text: value
        }
      when /\[question\((\d+)\),\s*question_pipe\("(.*)"\)\]/
        {
          question_id: $1.to_i,
          question_pipe: $2,
          answer_text: value
        }
      when /\[question\((\d+)\)\]/
        {
          question_id: $1.to_i,
          answer_text: value
        }
      else
        fail "Didn't recognize pattern for #{key} => #{value} - you may have to parse your answers manually."
      end
    end
  end
end; end
