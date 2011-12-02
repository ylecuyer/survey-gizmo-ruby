require "spec_helper"
describe "Survey Gizmo Resource" do
  
  describe SurveyGizmo::Resource do
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
      
    it_should_behave_like 'an API object'
    it_should_behave_like 'an object with errors'
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
    it_should_behave_like 'an object with errors'
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
    it_should_behave_like 'an object with errors'
  
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
    it_should_behave_like 'an object with errors'
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
    it_should_behave_like 'an object with errors'
  end
end
