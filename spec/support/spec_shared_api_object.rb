shared_examples_for 'an API object' do
  before(:all) do
    SurveyGizmo.setup(user: 'test@test.com', password: 'password')
  end

  it "should be descendant of SurveyGizmo::Resource" do
    SurveyGizmo::Resource.descendants.should include(described_class)
  end

  context "#create" do
    it "should make a request" do
      stub_api_call(:put)
      described_class.create(create_attributes)
      a_request(:put, /#{@base}#{uri_paths[:create]}/).should have_been_made
    end

    it "should return a new instance" do
      stub_api_call(:put)
      obj = described_class.create(create_attributes)
      obj.should be_instance_of(described_class)
    end

    it "should set the attributes" do
      stub_request(:put, /#{@base}/).to_return(json_response(true, create_attributes))
      obj = described_class.create(create_attributes)
      obj.attributes.reject{|k,v| v.blank? }.should == create_attributes
    end
  end

  context "#get" do
    it "should make a request" do
      stub_request(:get, /#{@base}/).to_return(json_response(true, get_attributes))
      described_class.first(first_params)
      a_request(:get, /#{@base}#{uri_paths[:get]}/).should have_been_made
    end

    it "should set the attributes" do
      stub_request(:get, /#{@base}/).to_return(json_response(true, get_attributes))
      obj = described_class.first(first_params)
      obj.attributes.reject{|k,v| v.blank? }.should == get_attributes
    end

    it "should return false if the request fails" do
      stub_request(:get, /#{@base}/).to_return(json_response(false, "something is wrong"))
      described_class.first(first_params).should == nil
    end
  end

  context "instance#update" do
    before(:each) do
      @obj = described_class.new(get_attributes)
      @obj.__send__(:clean!)
    end

    it "should make a request" do
      stub_api_call(:post)
      @obj.update
      a_request(:post, /#{@base}#{uri_paths[:update]}/).should have_been_made
    end

    it 'should change object state to saved' do
      stub_api_call(:post)
      @obj.update(update_attributes)
      @obj.should be_saved
    end

    it "should not be marked saved if the request fails" do
      stub_api_call(:post, false)
      @obj.update
      @obj.should_not be_saved
    end

    xit "cannot be updated if new" do
      @obj.instance_variable_set('@_state', nil)
      @obj.update(update_attributes).should be_false
    end

  end

  context "instance#destroy" do
    before(:each) do
      @obj = described_class.new(get_attributes)
      @obj.__send__(:clean!)
    end

    it "should make a request" do
      stub_api_call(:delete)
      @obj.destroy
      a_request(:delete, /#{@base}#{uri_paths[:delete]}/).should have_been_made
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

  context '#destroy', :focused => true do
    it "should make a request" do
      stub_api_call(:delete)
      described_class.destroy(first_params)
      a_request(:delete, /#{@base}#{uri_paths[:delete]}/).should have_been_made
    end

    it "should return result" do
      stub_api_call(:delete)
      described_class.destroy(first_params).should be_true
    end
  end

  context 'instance#save' do
    it "should call create on a new resource" do
      stub_api_call(:put)
      obj = described_class.new(create_attributes)
      obj.save
      a_request(:put, /#{@base}#{uri_paths[:create]}/).should have_been_made
    end

    it "should call update on a created resource" do
      obj = described_class.new(get_attributes)
      obj.__send__(:clean!)
      stub_api_call(:post)
      obj.save
      a_request(:post, /#{@base}#{uri_paths[:update]}/).should have_been_made
    end
  end

  context '#all' do
    before(:all) do
      @array = [
        {:id => 1, :title => 'resource 1'},
        {:id => 2, :title => 'resource 2'},
        {:id => 3, :title => 'resource 3'}
      ]
    end

    it "should make a get request" do
      stub_request(:get, /#{@base}/).to_return(json_response(true, []))
      described_class.all(get_attributes)
      a_request(:get, /#{@base}#{uri_paths[:create]}/).should have_been_made
    end

    it "should create a collection using the class" do
      stub_request(:get, /#{@base}/).to_return(json_response(true, @array))
      collection = described_class.all(get_attributes)
      collection.should be_instance_of(Array)
    end

    it "should return instances of the class" do
      stub_request(:get, /#{@base}/).to_return(json_response(true, @array))
      collection = described_class.all(get_attributes)
      collection.first.should be_instance_of(described_class)
    end

    it "should include all elements" do
      stub_request(:get, /#{@base}/).to_return(json_response(true, @array))
      collection = described_class.all(get_attributes)
      collection.length.should == 3
    end
  end

end