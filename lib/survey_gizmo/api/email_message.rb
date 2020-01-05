module SurveyGizmo::API
  class EmailMessage
    include SurveyGizmo::Resource

    attribute :id,                Integer
    attribute :survey_id,         Integer
    attribute :campaign_id,       Integer
    attribute :invite_identity,   Integer
    attribute :subject,           String
    attribute :replies,           String
    attribute :medium,            String
    attribute :status,            String
    attribute :from,              Hash
    attribute :body,              Hash
    attribute :send,              Boolean

    # v4 fields
    attribute :_type,             String
    attribute :_subtype,          String
    attribute :messagetype,       String
    attribute :datecreated,       DateTime
    attribute :datemodified,      DateTime

    # v5 fields
    attribute :type,              String
    attribute :subtype,           String
    attribute :message_type,       String
    attribute :footer,            String
    attribute :embed_question,    Boolean
    attribute :disable_styles,    Boolean
    attribute :date_created,      DateTime
    attribute :date_modified,     DateTime

    @route = '/survey/:survey_id/surveycampaign/:campaign_id/emailmessage'
  end
end
