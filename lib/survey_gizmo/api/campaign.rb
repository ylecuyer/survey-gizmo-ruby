module SurveyGizmo; module API
  # @see SurveyGizmo::Resource::ClassMethods
  class Campaign
    include SurveyGizmo::Resource

    attribute :id,              Integer
    attribute :name,            String
    attribute :type,            String
    attribute :_type,           String
    attribute :_subtype,        String
    attribute :__subtype,       String
    attribute :status,          String
    attribute :uri,             String
    attribute :SSL,             Boolean
    attribute :slug,            String
    attribute :language,        String
    attribute :close_message,   String
    attribute :limit_responses, String
    attribute :tokenvariables,  Array
    attribute :survey_id,       Integer
    attribute :datecreated,     DateTime
    attribute :datemodified,    DateTime
    attribute :surveycampaign,  Integer
    attribute :copy,            Boolean

    @route = '/survey/:survey_id/surveycampaign'

    def contacts(conditions = {})
      Contact.all(conditions.merge(children_param_hash).merge(all_pages: !conditions[:page]))
    end

    def to_param_options
      { id: id, survey_id: survey_id }
    end
  end
end; end
