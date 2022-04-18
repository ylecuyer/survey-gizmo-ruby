module SurveyGizmo::API
  if SurveyGizmo.configuration.v5?
    include SurveyGizmo::V5
  else
    include SurveyGizmo::V4
  end
end
