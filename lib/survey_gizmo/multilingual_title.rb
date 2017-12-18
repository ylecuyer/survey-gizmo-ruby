# SurveyGizmo has a bad habit of returning titles in different formats when one is requesting via .all vs .first
module SurveyGizmo
  module MultilingualTitle
    extend ActiveSupport::Concern

    included do
      attribute :title, Hash
    end

    def title=(val)
      super(val.is_a?(Hash) ? val[SurveyGizmo.configuration.locale] : val)
    end
  end
end
