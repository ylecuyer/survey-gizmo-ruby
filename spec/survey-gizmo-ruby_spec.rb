require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "SurveyGizmo" do
  before(:each) do
    @base = 'https://restapi.surveygizmo.com/v1'
  end
  
  it "should have a base uri" do
    SurveyGizmo.base_uri.should == 'https://restapi.surveygizmo.com/v1'
  end
  
  it "should allow basic authentication configuration" do
    SurveyGizmo.setup(:user => 'test@test.com', :password => 'password')
    SurveyGizmo.default_options[:default_params].should == {'user:pass' => 'test@test.com:password'}
  end
  
  it "should raise an error if auth isn't configured"
  
  describe SurveyGizmo::Resource, :focused => true do
    before(:each) do
      SurveyGizmo.setup(:user => 'test@test.com', :password => 'password')
    end
    
    let(:described_class) { SurveyGizmoSpec::ResourceTest }
    
    let(:create_attributes){ {:title => 'Spec', :test_id => 5} }
    let(:get_attributes)   { create_attributes.merge(:id => 1) }
    let(:update_attributes){ {:title => 'Updated'} }
    let(:first_params){ {:id => 1} }
    let(:uri_paths){ 
      { 
        :get => '/test/1',
        :create => '/test/5/resource',
        :update => '/test/5/resource/1',
        :delete => '/test/5/resource/1'
      }
    }
    
    it "#new?" do
      described_class.new.should be_new
    end


    it '#reload' do
      stub_request(:get, /#{@base}/).to_return(json_response(true, get_attributes))
      obj = described_class.new(create_attributes)
      obj.attributes.reject{|k,v| v.blank? }.should == create_attributes
      obj.reload
      obj.attributes.reject{|k,v| v.blank? }.should == get_attributes
    end

    it '#valid?'
    it "should be in zombie state if requests fail"
    
    it_should_behave_like 'an API object'
  end
  
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
  
  describe SurveyGizmo::API::Question, :focused => false do
    let(:create_attributes){ {:survey_id => 1234, :page_id => 1, :title => 'Spec Question', :type => 'radio', :properties => {:required => true, :option_sort => false} } }
    let(:get_attributes)   { 
      h = create_attributes.merge(:id => 1, :_subtype => 'radio')
      h.delete(:type)
      h
    }
    let(:update_attributes){ {:survey_id => 1234, :page_id => 1, :title => 'Updated'} }
    let(:uri_paths){ 
      { :get => '/1234/surveyquestion/1',
        :create => '/1234/surveypage/1/surveyquestion',
        :update => '/1234/surveypage/1/surveyquestion/1',
        :delete => '/1234/surveypage/1/surveyquestion/1' 
      }
    }
    
    it_should_behave_like 'an API object'
    
    it "should handle the title hash returned from the API" do
      @question = described_class.new('title' => {'English' => 'Some title'})
      @question.title.should == 'Some title'
    end
    
    it "should handle the _subtype key" do
      @question = described_class.new(:_subtype => 'radio')
      @question.type.should == 'radio'
    end
  end
  
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
