# frozen_string_literal: true

require_relative '../../../lib/palantir'

describe Palantir::Extractors::Base::Sanitizer do
  describe 'the general API' do
    describe 'remove_falsities' do
      context 'when the string contains one false word' do
        it 'removes the false word' do
          expect(described_class.remove_falsities(string: 'WSB is for stock trading'))
            .to eq(' is for stock trading')
        end
      end

      context 'when the string contains multiple false words' do
        it 'removes all false words' do
          expect(described_class.remove_falsities(string: 'WSB is OK for stock trading'))
            .to eq(' is  for stock trading')
        end
      end
    end
  end
end
