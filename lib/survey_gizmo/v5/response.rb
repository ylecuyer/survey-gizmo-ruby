module SurveyGizmo::V5
  class Response
    include SurveyGizmo::Resource

    # Filters
    NO_TEST_DATA =   { field: 'is_test_data', operator: '<>', value: 1 }
    ONLY_COMPLETED = { field: 'status',     operator: '=',  value: 'Complete' }

    def self.submitted_since_filter(time)
      {
        field: 'date_submitted',
        operator: '>=',
        value: time.in_time_zone(SurveyGizmo.configuration.api_time_zone).strftime('%Y-%m-%d %H:%M:%S')
      }
    end

    attribute :id,                   Integer
    attribute :survey_id,            Integer
    attribute :contact_id,           Integer
    attribute :status,               String
    attribute :is_test_data,         Boolean
    attribute :meta,                 Hash       # READ-ONLY
    attribute :url,                  Hash       # READ-ONLY

    # v5 fields
    attribute :date_submitted,       DateTime
    attribute :date_started,         DateTime
    attribute :session_id,           String
    attribute :language,             String
    attribute :url_variables,        Hash
    attribute :survey_data,          Hash
    attribute :comment,              Hash
    attribute :subquestions,         Hash
    attribute :options,              Hash
    attribute :link_id,              String
    attribute :ip_address,           String
    attribute :referer,              String
    attribute :user_agent,           String
    attribute :response_time,        Integer
    attribute :data_quality,         Array
    attribute :longitude,            String
    attribute :latitude,             String
    attribute :country,              String
    attribute :city,                 String
    attribute :region,               String
    attribute :postal,               String
    attribute :dma,                  Boolean
    alias_attribute :submitted_at, :date_submitted
    alias_attribute :answers, :survey_data

    @route = '/survey/:survey_id/surveyresponse'

    def survey
      @survey ||= Survey.first(id: survey_id)
    end

    def parsed_answers
      answers.map do |k, v|
        Answer.new(children_params.merge(key: k, value: v, answer_text: v, submitted_at: submitted_at))
      end
    end
  end
end
