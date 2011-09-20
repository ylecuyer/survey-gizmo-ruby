module SurveyGizmo; module API
  class Question
    include SurveyGizmo::Resource
    
    attribute :id,            Integer
    attribute :title,         String
    attribute :type,          String
    attribute :description,   String
    attribute :properties,    Hash
    attribute :after,         Integer
    attribute :survey_id,     Integer
    attribute :page_id,       Integer
    
    alias_attribute :_subtype, :type
    
    # routing
    route '/survey/:survey_id/surveyquestion/:id', :via => :get
    route '/survey/:survey_id/surveypage/:page_id/surveyquestion', :via => :create
    route '/survey/:survey_id/surveypage/:page_id/surveyquestion/:id', :via => [:update, :delete]
    
    # survey gizmo sends a hash back for :title
    # @private
    def title_with_multilingual=(val)
      self.title_without_multilingual = val.is_a?(Hash) ? val['English'] : val
    end

    alias_method_chain :title=, :multilingual
    
    def to_param_options
      {:id => self.id, :survey_id => self.survey_id, :page_id => self.page_id}
    end
  end
end; end