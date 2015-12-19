module SurveyGizmoSpec
  class ResourceTest
    include SurveyGizmo::Resource

    attribute :id, Integer
    attribute :title, String
    attribute :test_id, Integer

    # routes
    route '/test/:id', :get
    route '/test/:test_id/resource', :create
    route '/test/:test_id/resource/:id', [:update, :delete]

    def to_param_options
      { id: id, test_id: test_id }
    end
  end

  class GenericResource
    include SurveyGizmo::Resource

    attribute :id, Integer
    attribute :title, String
  end
end
