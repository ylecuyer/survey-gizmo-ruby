shared_examples_for 'an object with errors' do
  before(:each) do
    stub_request(:any, /#{@base}/).to_return(json_response(false, 'There was an error!'))
  end

  context 'class methods' do
    it 'should raise errors' do
      expect { described_class.first(get_attributes) }.to raise_error
      expect { described_class.all(get_attributes).to_a }.to raise_error
    end
  end
end
