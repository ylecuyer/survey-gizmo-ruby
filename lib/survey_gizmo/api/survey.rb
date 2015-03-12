module SurveyGizmo; module API
  # @see SurveyGizmo::Resource::ClassMethods
  class Survey
    include SurveyGizmo::Resource

    # @macro [attach] virtus_attribute
    #   @return [$2]
    attribute :id,             Integer
    attribute :team,           Integer
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

    # @macro collection
    collection :pages

    # Statistics array of arrays looks like:
    # [["Partial", 2], ["Disqualified", 28], ["Complete", 15]]
    def number_of_completed_responses
      if statistics && !statistics.empty? && (completed_data = statistics.find {|a| a[0] == 'Complete'})
        completed_data[1]
      else
        0
      end
    end

    # @see SurveyGizmo::Resource#to_param_options
    def to_param_options
      {id: self.id}
    end
  end
end; end