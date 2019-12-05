shared_examples_for 'an API object' do
  it "should be descendant of SurveyGizmo::Resource" do
    expect(SurveyGizmo::Resource.descendants).to include(described_class)
  end

  context "#create" do
    it "should make a request and create a new instance" do
      stub_api_call(:put)
      obj = described_class.create(create_attributes)

      expect(obj).to be_instance_of(described_class)
      expect(a_request(:put, /#{@base}#{uri_paths[:create]}/)).to have_been_made
    end

    it "should set the attributes" do
      stub_request(:put, /#{@base}/).to_return(json_response(true, create_attributes))
      obj = described_class.create(create_attributes)

      expect(obj.attributes.reject { |k, v| v.blank? }).to eq(create_attributes_to_compare || create_attributes)
    end
  end

  context "#get" do
    it "should make a request and set the attributes" do
      stub_request(:get, /#{@base}/).to_return(json_response(true, get_attributes))
      obj = described_class.first(first_params)
      expect(a_request(:get, /#{@base}#{uri_paths[:get]}/)).to have_been_made
      expect(obj.attributes.reject { |k, v| v.blank? }).to eq(get_attributes_to_compare || get_attributes)
    end

    it "should return false if the request fails" do
      stub_request(:get, /#{@base}/).to_return(json_response(false, "something is wrong"))
      expect { described_class.first(first_params) }.to raise_error(SurveyGizmo::BadResponseError, "something is wrong")
    end
  end

  context "instance#destroy" do
    before(:each) do
      @obj = described_class.new(get_attributes)
    end

    it "should make a request" do
      stub_api_call(:delete)
      @obj.destroy
      expect(a_request(:delete, /#{@base}#{uri_paths[:delete]}/)).to have_been_made
    end

    it "cannot be destroyed if new" do
      @obj.id = nil
      expect { @obj.destroy }.to raise_error(RuntimeError, /No id; can't delete/)
    end
  end

  context '#destroy', :focused => true do
    it "should make a request" do
      stub_api_call(:delete)
      described_class.destroy(first_params)
      expect(a_request(:delete, /#{@base}#{uri_paths[:delete]}/)).to have_been_made
    end

    it "should return result" do
      stub_api_call(:delete)
      expect(described_class.destroy(first_params)).to be_truthy
    end
  end

  context 'instance#save' do
    it "should call create on a new resource" do
      stub_api_call(:put)
      obj = described_class.new(create_attributes)
      obj.save
      expect(a_request(:put, /#{@base}#{uri_paths[:create]}/)).to have_been_made
    end

    it "should call update on a created resource" do
      obj = described_class.new(get_attributes)
      stub_api_call(:post)
      obj.save
      expect(a_request(:post, /#{@base}#{uri_paths[:update]}/)).to have_been_made
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
      expect(iterator).to be_instance_of(Enumerator)
      collection = iterator.to_a
      expect(a_request(:get, /#{@base}#{uri_paths[:create]}/)).to have_been_made
      expect(collection.first).to be_instance_of(described_class)
      expect(collection.length).to eq(3)
    end
  end
end
