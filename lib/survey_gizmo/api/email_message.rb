module SurveyGizmo; module API
  # @see SurveyGizmo::Resource::ClassMethods
  class EmailMessage
    include SurveyGizmo::Resource

    attribute :id,                Integer
    attribute :survey_id,         Integer
    attribute :campaign_id,       Integer
    attribute :invite_identity,   Integer
    attribute :_type,             String
    attribute :_subtype,          String
    attribute :subject,           String
    attribute :replies,           String
    attribute :messagetype,       String
    attribute :medium,            String
    attribute :status,            String
    attribute :from,              Hash
    attribute :body,              Hash
    attribute :send,              Boolean
    attribute :datecreated,       DateTime
    attribute :datemodified,      DateTime

    route '/survey/:survey_id/surveycampaign/:campaign_id/emailmessage/:id', :via => [:get, :update, :delete]
    route '/survey/:survey_id/surveycampaign/:campaign_id/emailmessage', :via => :create

    def to_param_options
      { id: self.id, survey_id: self.survey_id, campaign_id: self.campaign_id }
    end
  end
end; end