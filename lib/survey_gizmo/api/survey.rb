module SurveyGizmo; module API
  # @see SurveyGizmo::Resource::ClassMethods
  class Survey
    include SurveyGizmo::Resource

    # @macro [attach] virtus_attribute
    #   @return [$2]
    attribute :id,             Integer
    attribute :team,           Array
    attribute :type,           String
    attribute :_subtype,       String
    attribute :status,         String
    attribute :forward_only,   Boolean
    attribute :title,          String
    attribute :internal_title, String
    attribute :title_ml,       Hash
    attribute :links,          Hash
    attribute :theme,          Integer
    attribute :blockby,        String
    attribute :languages,      Array
    attribute :statistics,     Array
    attribute :created_on,     DateTime
    attribute :modified_on,    DateTime
    attribute :copy,           Boolean

    route '/survey/:id', via: [:get, :update, :delete]
    route '/survey',     via: :create

    def pages
      @pages ||= SurveyGizmo::API::Page.all(survey_id: id)
    end

    # Sub question handling is in resource.rb.  It should probably be here instead but if it gets moved here
    # and people try to request all the questions for a specific page directly from a ::API::Question request,
    # sub questions will not be included!  So I left it there for least astonishment.
    def questions
      @questions ||= pages.map { |p| SurveyGizmo::API::Question.all(survey_id: id, page_id: p.id) }.flatten
    end

    # Statistics array of arrays looks like:
    # [["Partial", 2], ["Disqualified", 28], ["Complete", 15]]
    def number_of_completed_responses
      if statistics && !statistics.empty? && (completed_data = statistics.find {|a| a[0] == 'Complete'})
        completed_data[1]
      else
        0
      end
    end

    def server_has_new_results_since?(time)
      filters = [{
        field: 'datesubmitted',
        operator: '>=',
        value: time.in_time_zone("Eastern Time (US & Canada)").strftime('%Y-%d-%m %H:%M:%S')
      }]
      responses = SurveyGizmo::API::Response.all({ survey_id: self.id }, { page: 1, filters: filters })
      responses.size > 0
    end

    # @see SurveyGizmo::Resource#to_param_options
    def to_param_options
      { id: self.id }
    end

    # As of 2015-08-07, when you request data on multiple surveys from /survey, the team
    # variable comes back as "0".  If you request one survey at a time from /survey/{id}, it works correctly.
    def teams
      @individual_survey ||= SurveyGizmo::API::Survey.first(id: self.id)
      @individual_survey.team
    end

    def team_names
      teams.map { |t| t['name'] }
    end

    def belongs_to?(team)
      team_names.any? { |t| t == team }
    end
  end
end; end
