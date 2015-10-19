# Inclusion of this module must come AFTER the virtus call:
#    attribute :title

module SurveyGizmo
  module MultilingualTitle
    extend ActiveSupport::Concern

    included do
      alias_method_chain :title=, :multilingual
    end

    def title_with_multilingual=(val)
      self.title_without_multilingual = val.is_a?(Hash) ? val['English'] : val
    end
  end
end
