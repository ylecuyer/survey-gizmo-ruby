# SurveyGizmo has a bad habit of returning titles in different formats when one is requesting via .all vs .first
module SurveyGizmo
  module MultilingualTitle
    extend ActiveSupport::Concern

    included do
      attribute :title, Hash
      # Using attr_accessor because it's not an API field
      attr_accessor :title_ml
    end

    def title=(val)
      self.title_ml = val.is_a?(Hash) ? val : { SurveyGizmo.configuration.locale => val }
      super(val.is_a?(Hash) ? val[SurveyGizmo.configuration.locale] : val)
    end
  end
end
