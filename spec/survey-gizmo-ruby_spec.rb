require 'spec_helper'

describe SurveyGizmo do
  it 'should have a base uri' do
    SurveyGizmo.base_uri.should == 'https://restapi.surveygizmo.com/v3'
  end

  it "should allow basic authentication configuration" do
    SurveyGizmo.setup(user: 'test@test.com', password: 'password')
    SurveyGizmo.default_options[:default_params].should == {'user:md5' => 'test@test.com:5f4dcc3b5aa765d61d8327deb882cf99'}
  end

  it "should raise an error if auth isn't configured"
end
