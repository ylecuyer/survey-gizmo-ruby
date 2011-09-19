require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "SurveyGizmo" do
  before(:each) do
    @base = 'https://restapi.surveygizmo.com/v1/survey'
  end
  
  it "should have a base uri" do
    SurveyGizmo.base_uri.should == 'https://restapi.surveygizmo.com/v1/survey'
  end
  
  it "should allow basic authentication configuration" do
    SurveyGizmo.setup(:user => 'test@test.com', :password => 'password')
    SurveyGizmo.options.should == {:user => 'test@test.com', :password => 'password'}
  end
  
  it "should raise an error if auth isn't configured"
  
  describe SurveyGizmo::API::Survey do    
    let(:create_attributes){ {:title => 'Spec', :type => 'survey', :status => 'In Design'} }
    let(:get_attributes)   { create_attributes.merge(:id => 1234) }
    let(:update_attributes){ {:title => 'Updated'} }
    let(:uri_paths){ 
      h = { :create => '' }
      h.default = '/1234'
      h
    }
    
    it_should_behave_like 'an API object'
  end
  
  # describe SurveyGizmo::API::Question do
  #   
  # end
  
  def stub_api_call(method, result = true)
    stub_request(method, /#{@base}/).to_return(json_response(result, {}))
  end
  
  def request_params(opts = {})
    {"user:pass" => 'test@test.com:password'}.merge(opts)
  end
  
  def json_response(result, data)
    body = {:result_ok => result}
    result ? body.merge!(:data => data) : body.merge!(:message => data)
    {:headers => {'Content-Type' => 'application/json'}, :body => body.to_json}
  end
end
