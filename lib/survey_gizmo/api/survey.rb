module SurveyGizmo; module API
  class Survey
    include SurveyGizmo::Resource
    
    attribute :id, Integer
    attribute :title, String
    attribute :status, String
    attribute :type,  String, :default => 'survey'
    attribute :created_on, DateTime
    
  end
end; end