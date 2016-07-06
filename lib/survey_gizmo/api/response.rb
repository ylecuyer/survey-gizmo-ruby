module SurveyGizmo::API
  class Response
    include SurveyGizmo::Resource

    # Filters
    NO_TEST_DATA =   { field: 'istestdata', operator: '<>', value: 1 }
    ONLY_COMPLETED = { field: 'status',     operator: '=',  value: 'Complete' }

    def self.submitted_since_filter(time)
      {
        field: 'datesubmitted',
        operator: '>=',
        value: time.in_time_zone(SurveyGizmo.configuration.api_time_zone).strftime('%Y-%m-%d %H:%M:%S')
      }
    end

    attribute :id,                   Integer
    attribute :survey_id,            Integer
    attribute :contact_id,           Integer
    attribute :data,                 String
    attribute :status,               String
    attribute :is_test_data,         Boolean
    attribute :sResponseComment,     String
    attribute :variable,             Hash       # READ-ONLY
    attribute :meta,                 Hash       # READ-ONLY
    attribute :shown,                Hash       # READ-ONLY
    attribute :url,                  Hash       # READ-ONLY
    attribute :answers,              Hash       # READ-ONLY
    attribute :datesubmitted,        DateTime
    alias_attribute :submitted_at, :datesubmitted

    @route = '/survey/:survey_id/surveyresponse'

    def survey
      @survey ||= Survey.first(id: survey_id)
    end

    def parsed_answers
      filtered_answers = answers.select do |k, v|
        next false unless v.is_a?(FalseClass) || v.present?

        # Strip out "Other" answers that don't actually have the "other" text (they come back as two responses - one
        # for the "Other" option_id, and then a whole separate response for the text given as an "Other" response.
        if /\[question\((?<question_id>\d+)\),\s*option\((?<option_id>\d+)\)\]/ =~ k
          !answers.keys.any? { |key| key =~ /\[question\((#{question_id})\),\s*option\("(#{option_id})-other"\)\]/ }
        elsif /\[question\((?<question_id>\d+)\)\]/ =~ k
          !answers.keys.any? { |key| key =~ /\[question\((#{question_id})\),\s*option\("\d+-other"\)\]/ }
        else
          true
        end
      end

      filtered_answers.map do |k, v|
        Answer.new(children_params.merge(key: k, value: v, answer_text: v, submitted_at: submitted_at))
      end
    end
  end
end
