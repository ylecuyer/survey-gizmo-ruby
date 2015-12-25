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

    alias_method :submitted_at, :datesubmitted

    @route = '/survey/:survey_id/surveyresponse'

    def survey
      @survey ||= Survey.first(id: survey_id)
    end

    def parsed_answers
      answers.select do |k,v|
        next false unless v.is_a?(FalseClass) || v.present?

        # Strip out "Other" answers that don't actually have the "other" text.
        if k =~ /\[question\((\d+)\),\s*option\((\d+)\)\]/
          !answers.keys.any? { |key| key =~ /\[question\((#{$1})\),\s*option\("(#{$2})-other"\)\]/ }
        else
          true
        end
      end.map { |k,v| Answer.new(survey_id, id, submitted_at, k, v) }
    end

    def to_param_options
      { id: id, survey_id: survey_id }
    end
  end
end; end
