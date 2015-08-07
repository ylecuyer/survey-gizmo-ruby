module SurveyGizmoSpec
  module Methods
    def stub_api_call(method, result = true)
      stub_request(method, /#{@base}/).to_return(json_response(result, {}))
    end

    def json_response(result, data)
      body = { result_ok: result }
      result ? body.merge!(data: data) : body.merge!(message: data)
      {
        headers: { 'Content-Type' => 'application/json' },
        body: body.to_json
      }
    end
  end
end