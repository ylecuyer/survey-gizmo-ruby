shared_examples_for 'an API object' do
  it "should be descendant of SurveyGizmo::Resource" do
    SurveyGizmo::Resource.descendants.should include(described_class)
  end

  context "#create" do
    it "should make a request and create a new instance" do
      stub_api_call(:put)
      obj = described_class.create(create_attributes)

      obj.should be_instance_of(described_class)
      a_request(:put, /#{@base}#{uri_paths[:create]}/).should have_been_made
    end

    it "should set the attributes" do
      stub_request(:put, /#{@base}/).to_return(json_response(true, create_attributes))
      obj = described_class.create(create_attributes)

      obj.attributes.reject { |k, v| v.blank? }.should == (create_attributes_to_compare || create_attributes)
    end
  end

  context "#get" do
    it "should make a request and set the attributes" do
      stub_request(:get, /#{@base}/).to_return(json_response(true, get_attributes))
      obj = described_class.first(first_params)
      a_request(:get, /#{@base}#{uri_paths[:get]}/).should have_been_made
      obj.attributes.reject { |k, v| v.blank? }.should == (get_attributes_to_compare || get_attributes)
    end

    it "should return false if the request fails" do
      stub_request(:get, /#{@base}/).to_return(json_response(false, "something is wrong"))
      expect { described_class.first(first_params) }.to raise_error
    end
  end

  context "instance#destroy" do
    before(:each) do
      @obj = described_class.new(get_attributes)
    end

    it "should make a request" do
      stub_api_call(:delete)
      @obj.destroy
      a_request(:delete, /#{@base}#{uri_paths[:delete]}/).should have_been_made
    end

    it "cannot be destroyed if new" do
      @obj.id = nil
      expect { @obj.destroy }.to raise_error
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
      stub_api_call(:post)
      obj.save
      a_request(:post, /#{@base}#{uri_paths[:update]}/).should have_been_made
    end
  end

  context '#all' do
    let(:data) do
      [
        {:id => 1, :title => 'resource 1'},
        {:id => 2, :title => 'resource 2'},
        {:id => 3, :title => 'resource 3'}
      ]
    end

    it "should make a get request" do
      stub_request(:get, /#{@base}/).to_return(json_response(true, data))
      iterator = described_class.all(get_attributes.merge(page: 1))
      iterator.should be_instance_of(Enumerator)
      collection = iterator.to_a
      a_request(:get, /#{@base}#{uri_paths[:create]}/).should have_been_made
      collection.first.should be_instance_of(described_class)
      collection.length.should == 3
    end
  end
end
