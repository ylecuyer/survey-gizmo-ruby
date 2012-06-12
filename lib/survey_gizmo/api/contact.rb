module SurveyGizmo; module API
  # @see SurveyGizmo::Resource::ClassMethods
  class Contact
    include SurveyGizmo::Resource

    # @macro [attach] virtus_attribute
    #   @return [$2]
    attribute :id,                      Integer
    attribute :survey_id,               Integer
    attribute :campaign_id,             Integer
    attribute :estatus,                 String
    attribute :esubscriberstatus,       String
    attribute :semailaddress,           String
    attribute :sfirstname,              String
    attribute :slastname,               String
    attribute :sorganization,           String
    attribute :sdepartment,             String
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
    attribute :scustom1,                String
    attribute :scustom2,                String
    attribute :scustom3,                String
    attribute :scustom4,                String
    attribute :scustom5,                String
    attribute :scustom6,                String
    attribute :scustom7,                String
    attribute :scustom8,                String
    attribute :scustom9,                String
    attribute :scustom10,               String

    route '/survey/:survey_id/surveycampaign/:campaign_id/contact/:id', :via => [:get, :update, :delete]
    route '/survey/:survey_id/surveycampaign/:campaign_id/contact', :via => :create

    # @see SurveyGizmo::Resource#to_param_options
    def to_param_options
      {:id => self.id, :survey_id => self.survey_id, :campaign_id => self.campaign_id}
    end
  end
end; end