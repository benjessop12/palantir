# frozen_string_literal: true

require_relative '../../lib/palantir'

describe Palantir::Extractors::Reddit do
  context 'with high risk' do
    let(:dummy_class) { described_class.new(risk_level: 'HIGH') }

    describe 'in general' do
      it 'will analyze the high risk subreddit' do
        expect(dummy_class.subreddit).to eq('wallstreetbets')
      end

      describe 'detect_data_from_string' do
        let(:expected_formatted_data) do
          {
            PLTR: [
              {
                date: '',
                currency: '$4.20'
              }
            ],
            NIO: [
              {
                date: '4-20',
                currency: '$6.90'
              }
            ]
          }
        end

        let(:first_string) { 'this comment has PLTR valued at $4.20' }
        let(:second_string) { 'this thinks NIO will reach $6.90 on 4/20' }
        let(:third_string) { 'no value comment' }

        it 'iterates over subreddit comments and segments basic values' do
          dummy_class.send(:detect_data_from_string, string: first_string)
          dummy_class.send(:detect_data_from_string, string: second_string)
          dummy_class.send(:detect_data_from_string, string: third_string)
          expect(dummy_class.results).to eq(expected_formatted_data)
        end
      end
    end
  end
end
