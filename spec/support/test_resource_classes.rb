module SurveyGizmoSpec
  class ResourceTest
    include SurveyGizmo::Resource

    attribute :id, Integer
    attribute :title, String
    attribute :test_id, Integer

    # routes
    route '/test/:id', :via => :get
    route '/test/:test_id/resource', :via => :create
    route '/test/:test_id/resource/:id', :via => [:update, :delete]

    def to_param_options
      {:id => self.id, :test_id => self.test_id}
    end
  end

  class GenericResource
    include SurveyGizmo::Resource

    attribute :id, Integer
    attribute :title, String
  end
end