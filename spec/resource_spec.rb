require 'spec_helper'

describe 'Survey Gizmo Resource' do
  let(:create_attributes_to_compare) { }
  let(:get_attributes_to_compare) { }

  describe SurveyGizmo::Resource do
    let(:described_class)   { SurveyGizmoSpec::ResourceTest }
    let(:create_attributes) { { title: 'Spec', test_id: 5 } }
    let(:update_attributes) { { title: 'Updated' } }
    let(:first_params)      { { id: 1, test_id: 5 } }
    let(:get_attributes)    { create_attributes.merge(id: 1) }
    let(:uri_paths){
      {
        get:    '/test/1',
        create: '/test/5/resource',
        update: '/test/5/resource/1',
        delete: '/test/5/resource/1'
      }
    }

    it '#reload' do
      stub_request(:get, /#{@base}/).to_return(json_response(true, get_attributes))
      obj = described_class.new(get_attributes.merge(update_attributes))
      expect(obj.attributes.reject { |k, v| v.blank? }).to eq(get_attributes.merge(update_attributes))
      obj.reload
      expect(obj.attributes.reject { |k, v| v.blank? }).to eq(get_attributes)
    end

    it 'should raise an error if params are missing' do
      expect(lambda {
        SurveyGizmoSpec::ResourceTest.destroy(test_id: 5)
      }).to raise_error(SurveyGizmo::URLError, 'Missing RESTful parameters in request: `:id`')
    end

    it_should_behave_like 'an API object'
    it_should_behave_like 'an object with errors'

    context '#filters_to_query_string' do
      let(:page)    { 2 }
      let(:filters) { { page: page, filters: [{ field: 'istestdata', operator: '<>', value: 1 }] } }

      it 'should generate the correct page request' do
        expect(SurveyGizmoSpec::ResourceTest.send(:filters_to_query_string, { page: page })).to eq("?page=#{page}")
      end

      it 'should generate the correct filter fragment' do
        expect(SurveyGizmoSpec::ResourceTest.send(:filters_to_query_string, filters)).to eq("?filter%5Bfield%5D%5B0%5D=istestdata&filter%5Boperator%5D%5B0%5D=%3C%3E&filter%5Bvalue%5D%5B0%5D=1&page=#{page}")
      end
    end
  end

  describe SurveyGizmo::API::Survey do
    let(:create_attributes) { { title: 'Spec', type: 'survey', status: 'In Design' } }
    let(:get_attributes)    { create_attributes.merge(first_params) }
    let(:update_attributes) { { title: 'Updated'} }
    let(:first_params)      { { id: 1234} }
    let(:uri_paths){
      h = { :create => '/survey' }
      h.default = '/survey/1234'
      h
    }

    it_should_behave_like 'an API object'
    it_should_behave_like 'an object with errors'

    it 'should parse the number of completed records correctly' do
      survey = described_class.new('statistics' => [['Partial', 2], ['Disqualified', 28], ['Complete', 15]])
      expect(survey.number_of_completed_responses).to eq(15)
    end

    it 'should determine if there are new results' do
      stub_request(:get, /#{@base}\/survey\/1\/surveyresponse/).to_return(json_response(true, []))

      survey = described_class.new(id: 1)
      expect(survey.server_has_new_results_since?(Time.now)).to be_falsey
      expect(a_request(:get, /#{@base}\/survey\/1\/surveyresponse/)).to have_been_made
    end
  end

  describe SurveyGizmo::API::Question do
    let(:base_params)       { {survey_id: 1234, page_id: 1} }
    let(:create_attributes) { base_params.merge(title: 'Spec Question', type: 'radio', properties: { 'required' => true, 'option_sort' => false }) }
    let(:update_attributes) { base_params.merge(title: 'Updated') }
    let(:first_params)      { base_params.merge(id: 1) }
    let(:get_attributes)    { create_attributes.merge(id: 1).reject { |k, v| k == :properties } }
    let(:uri_paths) {
      { :get =>    '/survey/1234/surveyquestion/1',
        :create => '/survey/1234/surveypage/1/surveyquestion',
        :update => '/survey/1234/surveypage/1/surveyquestion/1',
        :delete => '/survey/1234/surveypage/1/surveyquestion/1'
      }
    }

    it_should_behave_like 'an API object'
    it_should_behave_like 'an object with errors'

    it 'should handle the title hash returned from the API' do
      expect(described_class.new('title' => {'English' => 'Some title'}).title).to eq('Some title')
    end

    it 'should handle the _subtype key' do
      expect(described_class.new(:_subtype => 'radio').type).to eq('radio')
    end

    it 'should find the survey' do
      stub_request(:get, /#{@base}\/survey\/1234/).to_return(json_response(true, get_attributes))
      described_class.new(base_params).survey
      expect(a_request(:get, /#{@base}\/survey\/1234/)).to have_been_made
    end

    context 'options' do
      let(:survey_id) { 15 }
      let(:question_id) { 23 }
      let(:body_data) do
        {
          "id" => question_id,
          "title" => {"English"=>"How likely are you to bang your head to Bohemian Rhapsody?"},
          "options"=>
             [
               {
                 "id" => 10014,
                 "title" => {"English"=>"0 = Not at all likely"},
                 "value" => "0 = Not at all likely"
               },
               {
                 "id" => 10015,
                 "title" => {"English"=>"1"},
                 "value" => "1"
               }
             ]
        }
      end

      context 'option parsing' do
        before do
          stub_request(:get, /#{@base}\/survey\/#{survey_id}\/surveyquestion\/#{question_id}/).to_return(json_response(true, body_data))
        end

        it 'correctly parses options out of question data' do
          question = described_class.first(survey_id: survey_id, id: question_id)
          expect(question.options.all? { |o| o.question_id == question_id && o.survey_id == survey_id }).to be_truthy
          expect(question.options.map { |o| o.id }).to eq([10014, 10015])
          expect(a_request(:get, /#{@base}\/.*surveyoption/)).to_not have_been_made
        end

        it 'correctly parses sub question options' do
          question = described_class.new(survey_id: survey_id, id: question_id + 1, parent_question_id: question_id)
          expect(question.parent_question.id).to eq(described_class.new(body_data).id)
          expect(question.options.all? { |o| o.question_id == question.id && o.survey_id == survey_id }).to be_truthy
          expect(question.options.map { |o| o.id }).to eq([10014, 10015])
          expect(a_request(:get, /#{@base}\/survey\/#{survey_id}\/surveyquestion\/#{question_id}/)).to have_been_made
        end
      end
    end

    context 'subquestions' do
      let(:parent_id) { 33 }
      let(:skus) { [544, 322] }
      let(:question_with_subquestions) { described_class.new(id: parent_id, survey_id: 1234, sub_question_skus: skus) }

      it 'should have no subquestions' do
        expect(described_class.new.sub_questions).to eq([])
      end

      it 'should have 2 subquestions and they should have the right parent question' do
        stub_request(:get, /#{@base}/).to_return(json_response(true, get_attributes))
        expect(question_with_subquestions.sub_questions.size).to eq(2)

        question_with_subquestions.sub_questions.first.parent_question
        expect(a_request(:get, /#{@base}\/survey\/1234\/surveyquestion\/#{parent_id}/)).to have_been_made
        skus.each do |sku|
          expect(a_request(:get, /#{@base}\/survey\/1234\/surveyquestion\/#{sku}/)).to have_been_made
        end
      end

      context 'and shortname' do
        let(:sku) { 6 }
        let(:question_with_subquestions) { described_class.new(id: parent_id, survey_id: 1234, sub_question_skus: [["0", sku], ["foo", 8]]) }

        it 'should have 2 subquestions and they should have the right parent question' do
          stub_request(:get, /#{@base}/).to_return(json_response(true, get_attributes))
          expect(question_with_subquestions.sub_questions.size).to eq(2)

          question_with_subquestions.sub_questions.first.parent_question
          expect(a_request(:get, /#{@base}\/survey\/1234\/surveyquestion\/#{parent_id}/)).to have_been_made
          expect(a_request(:get, /#{@base}\/survey\/1234\/surveyquestion\/#{sku}/)).to have_been_made
        end
      end
    end
  end

  describe SurveyGizmo::API::Option do
    let(:survey_and_page)   { {survey_id: 1234, page_id: 1} }
    let(:create_attributes) { survey_and_page.merge(question_id: 1, title: 'Spec Question', value: 'Spec Answer') }
    let(:update_attributes) { survey_and_page.merge(question_id: 1, title: 'Updated') }
    let(:first_params)      { survey_and_page.merge(id: 1, question_id: 1) }
    let(:get_attributes)    { create_attributes.merge(id: 1) }
    let(:uri_paths) {
      h = { :create => '/survey/1234/surveypage/1/surveyquestion/1/surveyoption' }
      h.default = '/survey/1234/surveypage/1/surveyquestion/1/surveyoption/1'
      h
    }

    it_should_behave_like 'an API object'
    it_should_behave_like 'an object with errors'
  end

  describe SurveyGizmo::API::Page do
    let(:create_attributes) { {:survey_id => 1234, :title => 'Spec Page' } }
    let(:get_attributes)    { create_attributes.merge(:id => 1) }
    let(:update_attributes) { {:survey_id => 1234, :title => 'Updated'} }
    let(:first_params)      { {:id => 1, :survey_id => 1234 } }
    let(:uri_paths){
      h = { :create => '/survey/1234/surveypage' }
      h.default = '/survey/1234/surveypage/1'
      h
    }

    it_should_behave_like 'an API object'
    it_should_behave_like 'an object with errors'
  end

  describe SurveyGizmo::API::Response do
    let(:create_attributes) { {:survey_id => 1234, :datesubmitted => "2015-04-15 05:46:30" } }
    let(:create_attributes_to_compare) { create_attributes.merge(:datesubmitted => Time.parse("2015-04-15 05:46:30 -0400")) }
    let(:get_attributes)    { create_attributes.merge(:id => 1) }
    let(:get_attributes_to_compare)    { create_attributes_to_compare.merge(:id => 1) }
    let(:update_attributes) { {:survey_id => 1234, :title => 'Updated'} }
    let(:first_params)      { {:id => 1, :survey_id => 1234 } }
    let(:uri_paths){
      h = { :create => '/survey/1234/surveyresponse' }
      h.default = '/survey/1234/surveyresponse/1'
      h
    }

    it_should_behave_like 'an API object'
    it_should_behave_like 'an object with errors'

    context 'during EST' do
      let(:create_attributes) { {:survey_id => 1234, :datesubmitted => "2015-01-15 05:46:30" } }
      let(:create_attributes_to_compare) { create_attributes.merge(:datesubmitted => Time.parse("2015-01-15 05:46:30 -0500")) }

      it_should_behave_like 'an API object'
      it_should_behave_like 'an object with errors'
    end

    context 'answers' do
      let(:survey_id) { 6 }
      let(:response_id) { 7 }
      let(:timestamp) { '2015-01-02'.to_time(:utc) }
      let(:answers) do
        {
          '[question(3), option("10021-other")]' => 'Some other text field answer',
          '[question(3), option(10021)]' => 'Other (required)',
          '[question(5)]' => 'VERY important',
          '[question(6)]' => nil,
          '[question(7), option(10001)]' => nil,
          '[question(8)]' => false,
          '[question(9), option(10002)]' => '16',
          '[question(10), question_pipe("Que aplicación")]' => '5 = Extremely important',
          '[question(11), question_pipe(10527)]' => 'This product was too expensive',
          # Sometimes surveygizmo only includes the option with the "other" answer.  =(
          '[question(12)]' => 'Other - Please explain',
          '[question(12), option("10017-other")]' => 'I understood...',
          '[question(13), option(0)]' => '12345'
        }
      end

      it 'should propagate time, survey_id, and response_id' do
        response = described_class.new(
          answers: answers.select { |k, v| k == "[question(5)]"},
          survey_id: survey_id,
          id: response_id,
          submitted_at: timestamp
        )
        expect(response.parsed_answers.map { |a| a.to_hash }).to eq([ { survey_id: survey_id, response_id: response_id, question_id: 5, answer_text: "VERY important", submitted_at: timestamp }])
      end

      it 'should parse the answers and remove extraneous answers' do
        expect(described_class.new(answers: answers, survey_id: 1).parsed_answers.map { |a| a.to_hash }).to eq([
          { survey_id: 1, question_id: 3, option_id: 10021, other_text: 'Some other text field answer' },
          { survey_id: 1, question_id: 5, answer_text: 'VERY important' },
          { survey_id: 1, question_id: 8, answer_text: 'false' },
          { survey_id: 1, question_id: 9, option_id: 10002 },
          { survey_id: 1, question_id: 10, question_pipe: 'Que aplicación', answer_text: '5 = Extremely important' },
          { survey_id: 1, question_id: 11, question_pipe: '10527', answer_text: 'This product was too expensive' },
          { survey_id: 1, question_id: 12, option_id: 10017, other_text: 'I understood...' },
          { survey_id: 1, question_id: 13, answer_text: '12345' }
        ])
      end
    end
  end

  describe SurveyGizmo::API::AccountTeams do
    pending('Need an account with admin privileges to test this')
    let(:create_attributes) { { teamid: 1234, teamname: 'team' } }
    let(:get_attributes)    { create_attributes.merge(id: 1234) }
    let(:update_attributes) { create_attributes }
    let(:first_params)      { { teamname: 'team' } }
    let(:uri_paths) do
      h = { :create => '/account_teams/1234' }
      h.default = '/account_teams/1234'
      h
    end

    #it_should_behave_like 'an API object'
    #it_should_behave_like 'an object with errors'
  end
end
