module SurveyGizmo::V4
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

    @route = '/survey/:survey_id/surveycampaign/:campaign_id/emailmessage'
  end
end
