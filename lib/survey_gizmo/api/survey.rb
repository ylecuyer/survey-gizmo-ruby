module SurveyGizmo; module API
  class Survey
    include SurveyGizmo::Resource
    
    attribute :id,          Integer
    attribute :title,       String
    attribute :status,      String
    attribute :type,        String,   :default => 'survey'
    attribute :links,       Hash
    attribute :created_on,  DateTime
    
    route '/survey/:id', :via => [:get, :update, :delete]
    route '/survey',     :via => :create
    
    collection :pages
    
    def to_param_options
      {:id => self.id}
    end
  end
end; end