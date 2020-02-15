module SurveyGizmo::V5
  class Contact
    include SurveyGizmo::Resource

    attribute :id,                      Integer
    attribute :survey_id,               Integer
    attribute :campaign_id,             Integer

    # v5 fields
    attribute :date_last_sent,          DateTime
    attribute :division,                String
    attribute :team,                    String
    attribute :group,                   String
    attribute :role,                    String

    attribute :status,                  String
    attribute :subscriber_status,       String
    attribute :email_address,           String
    attribute :first_name,              String
    attribute :last_name,               String
    attribute :organization,            String
    attribute :department,              String
    attribute :business_phone,          String
    attribute :home_phone,              String
    attribute :fax_phone,               String
    attribute :mailing_address,         String
    attribute :mailing_address2,        String
    attribute :mailing_address_city,    String
    attribute :mailing_address_state,   String
    attribute :mailing_address_country, String
    attribute :mailing_address_postal,  String
    attribute :title,                   String
    attribute :url,                     String
    attribute :customfield1,            String
    attribute :customfield2,            String
    attribute :customfield3,            String
    attribute :customfield4,            String
    attribute :customfield5,            String
    attribute :customfield6,            String
    attribute :customfield7,            String
    attribute :customfield8,            String
    attribute :customfield9,            String
    attribute :customfield10,           String
    @route = '/survey/:survey_id/surveycampaign/:campaign_id/contact'
  end
end
