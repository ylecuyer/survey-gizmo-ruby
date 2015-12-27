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
    # Unfortunately if pages is an attribute, then save and update requests will collide with the differing response
    # types to Survey.all and Survey.first and cause an incorrect reload
    # attribute :pages,          Array[Page]

    @route = '/survey'

    def pages
      # SurveyGizmo sends down the page info to .first requests but NOT to .all requests, so we must load pages manually
      # We should be able to just .reload this Survey BUT we can't make :pages a Virtus attribute without requiring a
      # call to this method during Survey.save
      @pages ||= Page.all(children_params.merge(all_pages: true)).to_a
      @pages.each { |p| p.attributes = children_params }
    end

    # Sub question handling is in resource.rb and page.rb.  It should probably be here instead but if it gets moved
    # here and people try to request all the questions for a specific page directly from a ::API::Question request or
    # from Page.questions, sub questions will not be included!  So I left it there for least astonishment.
    def questions
      @questions ||= pages.flat_map { |p| p.questions }
    end

    def actual_questions
      questions.reject { |q| q.type =~ /^(instructions|urlredirect|logic)$/ }
    end

    def responses(conditions = {})
      Response.all(conditions.merge(children_params).merge(all_pages: !conditions[:page]))
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
      Response.all(children_params.merge(page: 1, resultsperpage: 1, filters: Response.submitted_since_filter(time))).to_a.size > 0
    end

    # As of 2015-12-18, when you request data on multiple surveys from /survey, the team variable comes
    # back as "0".  If you request one survey at a time from /survey/{id}, it is populated correctly.
    def teams
      @individual_survey ||= self.reload
      @individual_survey.team
    end

    def team_names
      teams.map { |t| t['name'] }
    end

    def belongs_to?(team)
      team_names.any? { |t| t == team }
    end

    def campaigns
      @campaigns ||= Campaign.all(children_params.merge(all_pages: true)).to_a
    end
  end
end; end
