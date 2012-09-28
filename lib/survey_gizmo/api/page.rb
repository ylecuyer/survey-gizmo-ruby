module SurveyGizmo; module API
  # @see SurveyGizmo::Resource::ClassMethods
  class Page
    include SurveyGizmo::Resource

    # @macro [attach] virtus_attribute
    #   @return [$2]
    attribute :id,            Integer
    attribute :title,         Hash
    attribute :description,   String
    attribute :properties,    Hash
    attribute :after,         Integer
    attribute :survey_id,     Integer


    # routing
    route '/survey/:survey_id/surveypage', :via => :create
    route '/survey/:survey_id/surveypage/:id', :via => [:get, :update, :delete]

    # @macro collection
    collection :questions

    # survey gizmo sends a hash back for :title
    # @private
    def title_with_multilingual=(val)
      self.title_without_multilingual = val.is_a?(Hash) ? val : val['English']
    end

    alias_method_chain :title=, :multilingual

    # @see SurveyGizmo::Resource#to_param_options
    def to_param_options
      {:id => self.id, :survey_id => self.survey_id}
    end
  end
end; end