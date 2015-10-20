# SurveyGizmo has a bad habit of returning titles in different formats when one is
# requesting all surveys vs. an individual survey.

module SurveyGizmo
  module MultilingualTitle
    extend ActiveSupport::Concern

    included do
      attribute :title, Hash
      alias_method_chain :title=, :multilingual
    end

    def title_with_multilingual=(val)
      self.title_without_multilingual = val.is_a?(Hash) ? val['English'] : val
    end
  end
end
