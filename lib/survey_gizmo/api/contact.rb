module SurveyGizmo::API
  class Contact
    include SurveyGizmo::Resource

    attribute :id,                      Integer
    attribute :survey_id,               Integer
    attribute :campaign_id,             Integer

    # v4 fields
    attribute :estatus,                 String
    attribute :esubscriberstatus,       String
    attribute :semailaddress,           String
    attribute :sfirstname,              String
    attribute :slastname,               String
    attribute :sorganization,           String
    attribute :sdepartment,             String
    attribute :sbusinessphone,          String
    attribute :shomephone,              String
    attribute :sfaxphone,               String
    attribute :sworkphone,              String
    attribute :smailingaddress,         String
    attribute :smailingaddress2,        String
    attribute :smailingaddresscity,     String
    attribute :smailingaddressstate,    String
    attribute :smailingaddresscountry,  String
    attribute :smailingaddresspostal,   String
    attribute :stitle,                  String
    attribute :surl,                    String
    attribute :scustomfield1,           String
    attribute :scustomfield2,           String
    attribute :scustomfield3,           String
    attribute :scustomfield4,           String
    attribute :scustomfield5,           String
    attribute :scustomfield6,           String
    attribute :scustomfield7,           String
    attribute :scustomfield8,           String
    attribute :scustomfield9,           String
    attribute :scustomfield10,          String

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
