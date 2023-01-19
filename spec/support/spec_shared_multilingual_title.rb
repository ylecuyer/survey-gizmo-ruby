shared_examples_for 'a MultilingualTitle object' do
  let(:object) { described_class.new }

  describe 'title=' do
    before(:each) do
      object.title = payload
    end

    context 'with a Hash' do
      let(:payload) { { 'English' => 'Title', 'French' => 'Titre' } }

      it 'uses the raw value to set title_ml property' do
        expect(object.title_ml).to eq(payload)
      end

      it 'sets title to the right value' do
        expect(object.title).to eq('Title')
      end
    end

    context 'with a String' do
      let(:payload) { 'Title' }

      it 'creates a fallback hash to set title_ml property' do
        expect(object.title_ml).to eq('English' => payload)
      end

      it 'sets title to the right value' do
        expect(object.title).to eq(payload)
      end
    end

    context 'with a different locale' do
      before(:each) do
        SurveyGizmo.configure do |config|
          config.locale = 'French'
        end
        object.title = payload
      end

      after(:each) do
        SurveyGizmo.reset!
      end

      context 'with a Hash' do
        let(:payload) { { 'English' => 'Title', 'French' => 'Titre' } }

        it 'uses the raw value to set title_ml property' do
          expect(object.title_ml).to eq(payload)
        end

        it 'sets title to the right value' do
          expect(object.title).to eq('Titre')
        end
      end

      context 'with a String' do
        let(:payload) { 'Titre' }

        it 'creates a valid fallback hash to set title_ml property' do
          expect(object.title_ml).to eq('French' => payload)
        end

        it 'sets title to the right value' do
          expect(object.title).to eq(payload)
        end
      end
    end
  end
end
