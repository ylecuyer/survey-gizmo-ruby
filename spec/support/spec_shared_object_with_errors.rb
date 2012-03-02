shared_examples_for 'an object with errors' do
  before(:each) do
    SurveyGizmo.setup(:user => 'test@test.com', :password => 'password')
    stub_request(:any, /#{@base}/).to_return(json_response(false, 'There was an error!'))
  end
  
  it "should be in zombie state if requests fail"

  context "class methods" do
    it { described_class.first(get_attributes).should be_nil }
    it { described_class.all(get_attributes).should be_empty }    
  end

  context "instance methods" do
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
  
    it "should empty the errors array if object gets saved" do
      stub_request(:any, /#{@base}/).to_return(json_response(false, 'There was an error!'), json_response(true, get_attributes))
      @obj.save.should == false
      @obj.errors.should_not be_empty
      @obj.save.should == true
      @obj.errors.should be_empty
    end
  end
end