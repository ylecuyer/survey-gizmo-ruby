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
    
  describe SurveyGizmo::API::Survey, :focused => true do
    before(:each) do
      SurveyGizmo.setup(:user => 'test@test.com', :password => 'password')
    end
    
    it "#new?" do
      described_class.new.should be_new
    end
    
    
    it '#reload' do
      stub_request(:get, /#{@base}/).to_return(json_response(true, {:title => 'Spec', :id => 1234, :type => "survey"}))
      obj = described_class.new(:title => 'Foo')
      obj.title.should == 'Foo'
      obj.reload
      obj.title.should == 'Spec'
    end
    
    it '#valid?'
    it "should be in zombie state if requests fail"
    
    context "create" do
      it "should make a request" do
        stub_api_call(:put)
        described_class.create(:title => 'Test', :type => 'survey')
        a_request(:put, @base).with(:query => request_params({:title => 'Test', :type => 'survey'})).should have_been_made
      end
      
      it "should return a new instance" do
        stub_api_call(:put)
        obj = described_class.create(:title => 'Spec', :type => 'survey')
        obj.title.should == "Spec"
      end
    end
    
    context "get" do
      it "should make a request" do
        stub_request(:get, /#{@base}/).to_return(json_response(true, {:title => 'Spec', :id => 1234, :type => "survey"}))
        described_class.get(1234)
        a_request(:get, /#{@base}\/1234/).should have_been_made
      end
    
      it "should set the attributes" do
        stub_request(:get, /#{@base}/).to_return(json_response(true, {:title => 'Spec', :id => 1234, :type => "survey"}))
        obj = described_class.get(1234)
        obj.title.should == 'Spec'
        obj.id.should == 1234
      end
    
      it "should return false if the request fails" do
        stub_request(:get, /#{@base}/).to_return(json_response(false, "something is wrong"))
        described_class.get(1234).should == false
      end
    end
    
    context "update" do
      before(:each) do
        @obj = described_class.new({:title => 'Spec', :id => 1234, :type => "survey"})
        @obj.__send__(:clean!)
      end
      
      it "should make a request" do
        stub_api_call(:post)
        @obj.update
        a_request(:post, /#{@base}\/1234/).should have_been_made
      end
      
      it 'should change object state to saved' do
        stub_api_call(:post)
        @obj.update({:title => 'Blah'})
        @obj.should be_saved
      end
      
      it "should not be marked saved if the request fails" do
        stub_api_call(:post, false)
        @obj.update
        @obj.should_not be_saved
      end
      
      xit "cannot be updated if new" do
        @obj.instance_variable_set('@_state', nil)
        @obj.update(:title => 'Updated').should be_false
      end
      
    end
    
    context "destroy" do
      before(:each) do
        @obj = described_class.new({:title => 'Spec', :id => 1234, :type => "survey"})
        @obj.__send__(:clean!)
      end
      
      it "should make a request" do
        stub_api_call(:delete)
        @obj.destroy
        a_request(:delete, /#{@base}\/1234/).should have_been_made
      end
      
      it 'should change object state to destroyed' do
        stub_api_call(:delete)
        @obj.destroy
        @obj.should be_destroyed
      end
      
      it "should not be marked destroyed if the request fails" do
        stub_api_call(:delete, false)
        @obj.destroy
        @obj.should_not be_destroyed
      end
      
      it "cannot be destroyed if new" do
        @obj.instance_variable_set('@_state', nil)
        @obj.destroy.should be_false
      end
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
