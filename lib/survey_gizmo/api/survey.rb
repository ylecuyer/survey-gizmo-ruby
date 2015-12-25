require 'survey_gizmo/api/page'

module SurveyGizmo; module API
  # @see SurveyGizmo::Resource::ClassMethods
  class Survey
    include SurveyGizmo::Resource

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
    attribute :pages,          Array[Page]

    @route = '/survey'

    def pages
      @pages ||= Page.all(children_param_hash.merge(all_pages: true)).to_a
      @pages.each { |p| p.attributes = children_param_hash }
    end

    # Sub question handling is in resource.rb.  It should probably be here instead but if it gets moved here
    # and people try to request all the questions for a specific page directly from a ::API::Question request,
    # sub questions will not be included!  So I left it there for least astonishment.
    def questions
      @questions ||= pages.map { |p| p.questions }.flatten
    end

    def actual_questions
      questions.reject { |q| q.type =~ /^(instructions|urlredirect|logic)$/ }
    end

    def responses(conditions = {})
      Response.all(conditions.merge(children_param_hash).merge(all_pages: !conditions[:page]))
    end

    # Statistics array of arrays looks like:
    # [["Partial", 2], ["Disqualified", 28], ["Complete", 15]]
    def number_of_completed_responses
      if statistics && !statistics.empty? && (completed_data = statistics.find { |a| a[0] == 'Complete' })
        completed_data[1]
      else
        0
      end
    end

    def server_has_new_results_since?(time)
      conditions = children_param_hash.merge(page: 1, resultsperpage: 1, filters: Response.submitted_since_filter(time))
      Response.all(conditions).to_a.size > 0
    end

    # As of 2015-12-18, when you request data on multiple surveys from /survey, the team variable comes
    # back as "0".  If you request one survey at a time from /survey/{id}, it is populated correctly.
    def teams
      @individual_survey ||= Survey.first(to_param_options)
      @individual_survey.team
    end

    def team_names
      teams.map { |t| t['name'] }
    end

    def belongs_to?(team)
      team_names.any? { |t| t == team }
    end

    def campaigns
      @campaigns ||= Campaign.all(children_param_hash.merge(all_pages: true)).to_a
    end

    def to_param_options
      { id: id }
    end
  end
end; end
