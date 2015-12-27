module SurveyGizmoSpec
  class ResourceTest
    include SurveyGizmo::Resource

    attribute :id, Integer
    attribute :title, String
    attribute :test_id, Integer

    # routes
    @route = {
      get: '/test/:id',
      create: '/test/:test_id/resource',
      update: '/test/:test_id/resource/:id',
      delete: '/test/:test_id/resource/:id'
    }

    def route_params
      { id: id, test_id: test_id }
    end
  end

  class GenericResource
    include SurveyGizmo::Resource

    attribute :id, Integer
    attribute :title, String
  end
end
