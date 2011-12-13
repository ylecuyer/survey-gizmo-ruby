module SurveyGizmo; module API
  class Response
    include SurveyGizmo::Resource
    
    attribute :id,            Integer
    attribute :data,          String
    attribute :status,        String
    attribute :survey_id,     Integer
        
    # routing
    route '/survey/:survey_id/surveyresponse',     :via => :create
    route '/survey/:survey_id/surveyresponse/:id', :via => [:get, :update, :delete]
    
    
    def to_param_options
      {:id => self.id, :survey_id => self.survey_id}
    end
  
  end
end; end