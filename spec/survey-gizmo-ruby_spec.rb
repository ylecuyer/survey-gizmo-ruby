require 'spec_helper'

describe "SurveyGizmo" do
  it "should have a base uri" do
    SurveyGizmo.base_uri.should == 'https://restapi.surveygizmo.com/v3'
  end

  it "should allow basic authentication configuration" do
    SurveyGizmo.setup(:user => 'test@test.com', :password => 'password')
    SurveyGizmo.default_options[:default_params].should == {'user:md5' => 'test@test.com:5f4dcc3b5aa765d61d8327deb882cf99'}
  end

  it "should raise an error if auth isn't configured"

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
        described_class.public_instance_methods.should include('resources')
        described_class.public_instance_methods.should include('resources=')
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
        described_class.public_instance_methods.should include('resources')
        described_class.public_instance_methods.should include('generic_resources')
      end

      it "can handle nested collections" do
        pending("Needs to be changed to work with suite. Right now it only passes in isolation.")
        SurveyGizmoSpec::ResourceTest.collection :generic_resources
        @generic_resource_list = [
          {:id => 1, :title => 'Generic Test 5'},
          {:id => 2, :title => 'Generic Test 6'},
          {:id => 3, :title => 'Generic Test 7'}
        ]

        @array << {:id => 99, :generic_resources => @generic_resource_list}
        obj = described_class.new(:id => 1, :resources => @array)
        obj.resources.first.should be_instance_of(SurveyGizmoSpec::ResourceTest)
        obj.resources.detect{|r| r.id == 99 }.generic_resources.first.should be_instance_of(SurveyGizmoSpec::GenericResource)
      end
    end
  end
end
