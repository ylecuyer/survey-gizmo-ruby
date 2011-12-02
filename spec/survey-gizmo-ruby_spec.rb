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
    
    it "should track descendants" do
      SurveyGizmo::Resource.descendants.should include(SurveyGizmoSpec::ResourceTest)
    end
    
    context "Errors" do
      before(:each) do
        stub_request(:any, /#{@base}/).to_return(json_response(false, 'There was an error!'))
      end

      it "should be in zombie state if requests fail"
      
      context "class" do
        it { described_class.first(get_attributes).should be_nil }
        it { described_class.all(get_attributes).should be_empty }
      end
      
      context "instance" do
        before(:each) do
          @obj = described_class.new(create_attributes)
        end
        
        it "should have an errors array" do
          @obj.errors.should == []
        end
        
        it "should add errors on failed requests" do
          @obj.save.should == false
          @obj.errors.should include('There was an error!')
        end
      end
    end
    
    it_should_behave_like 'an API object'
  end
  
  describe SurveyGizmo::API::Survey do
    let(:create_attributes){ {:title => 'Spec', :type => 'survey', :status => 'In Design'} }
    let(:get_attributes)   { create_attributes.merge(:id => 1234) }
    let(:update_attributes){ {:title => 'Updated'} }
    let(:first_params){ {:id => 1234} }
    let(:uri_paths){ 
      h = { :create => '/survey' }
      h.default = '/survey/1234'
      h
    }
    
    it_should_behave_like 'an API object'
  end
  
  describe SurveyGizmo::API::Question do
    let(:create_attributes){ {:survey_id => 1234, :page_id => 1, :title => 'Spec Question', :type => 'radio', :properties => {"required" => true, "option_sort" => false} } }
    let(:get_attributes)   { 
      create_attributes.merge(:id => 1)
    }
    let(:update_attributes){ {:survey_id => 1234, :page_id => 1, :title => 'Updated'} }
    let(:first_params){ {:id => 1, :survey_id => 1234} }
    let(:uri_paths){ 
      { :get =>    '/survey/1234/surveyquestion/1',
        :create => '/survey/1234/surveypage/1/surveyquestion',
        :update => '/survey/1234/surveypage/1/surveyquestion/1',
        :delete => '/survey/1234/surveypage/1/surveyquestion/1' 
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
  
  describe SurveyGizmo::API::Option do
    let(:create_attributes){ {:survey_id => 1234, :page_id => 1, :question_id => 1, :title => 'Spec Question', :value => 'Spec Answer'} }
    let(:get_attributes)   {
      create_attributes.merge(:id => 1)
    }
    let(:update_attributes){ {:survey_id => 1234, :page_id => 1, :question_id => 1, :title => 'Updated'} }
    let(:first_params){ {:id => 1, :survey_id => 1234, :page_id => 1, :question_id => 1} }
    let(:uri_paths){ 
      h = { :create => '/survey/1234/surveypage/1/surveyquestion/1/surveyoption' }
      h.default = '/survey/1234/surveypage/1/surveyquestion/1/surveyoption/1'
      h
    }
    
    it_should_behave_like 'an API object'
  
  end
  
  describe SurveyGizmo::API::Page do
    let(:create_attributes){ {:survey_id => 1234, :title => 'Spec Page'} }
    let(:get_attributes)   {
      create_attributes.merge(:id => 1)
    }
    let(:update_attributes){ {:survey_id => 1234, :title => 'Updated'} }
    let(:first_params){ {:id => 1, :survey_id => 1234 } }
    let(:uri_paths){ 
      h = { :create => '/survey/1234/surveypage' }
      h.default = '/survey/1234/surveypage/1'
      h
    }
    
    it_should_behave_like 'an API object'
  
  end
  
  
  describe "Collection" do
    before(:each) do
      @array = [
        {:id => 1, :title => 'Test 1'},
        {:id => 2, :title => 'Test 2'},
        {:id => 3, :title => 'Test 3'},
        {:id => 4, :title => 'Test 4'}
      ]      
      
      SurveyGizmo::Collection.send :public, *SurveyGizmo::Collection.private_instance_methods
    end
    
    let(:described_class) { SurveyGizmoSpec::CollectionTest }
  
    context "class" do
      before(:each) do
        described_class.collection :generic_resources
      end
      
      subject { SurveyGizmo::Collection.new(described_class, :generic_resources, @array) }
    
      it { should_not be_loaded }
      
      it "should set the options in the collections property" do
        described_class.collections.should == {:generic_resources => {:parent => described_class, :target => :generic_resources}}
      end
      
      it "should load objects using the given class" do
        subject.first.should be_instance_of(SurveyGizmoSpec::GenericResource)      
      end
    
      it "should be loaded before iteration" do
        subject.should_not be_loaded
        subject.each
        subject.should be_loaded
      end      
    end
    
    context '#collection' do
      before(:each) do
        described_class.collection(:resources, 'ResourceTest')
      end
      
      it { lambda{ described_class.collection :resources, 'ResourceTest'}.should_not raise_error }
      
      it "should have an accessor for the collection" do
        described_class.public_instance_methods.should include(:resources)
        described_class.public_instance_methods.should include(:resources=)
      end
      
      it "should set an empty collection" do
        described_class.collection(:resources, 'ResourceTest')
        obj = described_class.new()
        obj.resources.should be_empty
      end
      
      it "should set a collection" do
        described_class.collection(:resources, 'ResourceTest')
        obj = described_class.new()
        obj.resources = @array
        obj.resources.should be_instance_of(SurveyGizmo::Collection)
        obj.resources.length.should == @array.length
      end
      
      it "should set a collection from a hash" do
        obj = described_class.new(:id => 1, :resources => @array)
        obj.resources.should be_instance_of(SurveyGizmo::Collection)
        obj.resources.length.should == @array.length
      end
      
      it "can handle multiple collections" do
        described_class.collection(:generic_resources)
        described_class.public_instance_methods.should include(:resources)
        described_class.public_instance_methods.should include(:generic_resources)
      end
      
      it "can handle nested collections" do
        SurveyGizmoSpec::ResourceTest.collection :generic_resources
        @array2 = [
          {:id => 1, :title => 'Generic Test 5'},
          {:id => 2, :title => 'Generic Test 6'},
          {:id => 3, :title => 'Generic Test 7'}
        ]      
        
        @array << {:id => 99, :generic_resources => @array2}
        obj = described_class.new(:id => 1, :resources => @array)
        obj.resources.first.should be_instance_of(SurveyGizmoSpec::ResourceTest)
        obj.resources.last.generic_resources.first.should be_instance_of(SurveyGizmoSpec::GenericResource)
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
