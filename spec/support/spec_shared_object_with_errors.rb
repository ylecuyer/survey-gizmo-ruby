shared_examples_for 'an object with errors' do
  before(:each) do
    stub_request(:any, /#{@base}/).to_return(json_response(false, 'There was an error!'))
  end

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
      @obj.save.id.nil?.should == false
      @obj.errors.should be_empty
    end
  end
end