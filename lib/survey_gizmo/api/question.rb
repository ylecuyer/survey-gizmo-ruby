module SurveyGizmo; module API
  # @see SurveyGizmo::Resource::ClassMethods
  class Question
    include SurveyGizmo::Resource
    
    # @macro [attach] virtus_attribute
    #   @return [$2]
    attribute :id,            Integer
    attribute :title,         String
    attribute :type,          String
    attribute :description,   String
    attribute :properties,    Hash
    attribute :after,         Integer
    attribute :survey_id,     Integer
    attribute :page_id,       Integer, :default => 1
    
    alias_attribute :_subtype, :type
    
    route '/survey/:survey_id/surveyquestion/:id', :via => :get
    route '/survey/:survey_id/surveypage/:page_id/surveyquestion', :via => :create
    route '/survey/:survey_id/surveypage/:page_id/surveyquestion/:id', :via => [:update, :delete]
    
    # @macro collection
    collection :options
    
    # survey gizmo sends a hash back for :title
    # @private
    def title_with_multilingual=(val)
      self.title_without_multilingual = val.is_a?(Hash) ? val['English'] : val
    end

    alias_method_chain :title=, :multilingual
    
    # @see SurveyGizmo::Resource#to_param_options 
    def to_param_options
      {:id => self.id, :survey_id => self.survey_id, :page_id => self.page_id}
    end
  end
end; end