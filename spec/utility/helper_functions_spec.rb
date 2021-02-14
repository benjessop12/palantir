# frozen_string_literal: true

require_relative '../../lib/palantir'

describe Palantir::HelperFunctions do
  describe 'average_of' do
    context 'when given an array of integers' do
      it 'returns the average of the array of integers' do
        expect(described_class.average_of(array_of_ticker_data: [0, 5, 10, 15, 20, 25]))
          .to eq(12.5)
      end
    end
  end
end
