# frozen_string_literal: true

require 'timecop'

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

      context 'with results data' do
        let(:results) do
          {
            "PLTR": [
              {
                date: '2021-01-01',
                currency: '20'
              },
              {
                date: '2021-01-01',
                currency: '21'
              }
            ],
            "NIO": [
              {
                date: '2021-01-01',
                currency: '50'
              },
              {
                date: '2021-01-01',
                currency: '51'
              }
            ],
            "TSLA": [
              {
                date: '2021-01-01',
                currency: '100'
              },
              {
                date: '2021-01-02',
                currency: '102'
              }
            ]
          }
        end

        let(:defined_tickers) do
          %w[PLTR NIU]
        end

        before do
          dummy_class.instance_variable_set(:@results, results)
        end

        describe 'new_tickers' do
          it 'selects tickers that are not currently defined' do
            expect(dummy_class.send(:new_tickers, defined_tickers: defined_tickers)).to eq(%w[NIO TSLA])
          end
        end

        describe 'best_option' do
          before do
            allow(::Palantir::Clients::GoogleClient).to receive(:get_ticker).with('NIO').and_return(value: '45')
            allow(::Palantir::Clients::GoogleClient).to receive(:get_ticker).with('TSLA').and_return(value: '90')
          end

          it 'returns the highest weighed option, based off of shortest time and highest percentage increase' do
            expect(dummy_class.best_option(defined_tickers: defined_tickers)).to eq('NIO')
          end
        end

        describe 'strength_of_shill' do
          let(:current_price) { 100.0 }
          let(:strong_data) do
            [
              {
                date: '2021-01-02',
                currency: '105'
              },
              {
                date: '2021-01-01',
                currency: '110'
              }
            ]
          end
          let(:weak_data) do
            [
              {
                date: '2021-01-02',
                currency: '101'
              },
              {
                date: '2021-01-01',
                currency: '98'
              }
            ]
          end

          before do
            Timecop.freeze(Time.local(2020, 12, 1))
          end

          after do
            Timecop.return
          end

          context 'with strong data' do
            it 'returns a higher score' do
              expect(dummy_class.send(:strength_of_shill, current_price: current_price, data: strong_data))
                .to eq(32)
            end
          end

          context 'with weak data' do
            it 'returns a lower score' do
              expect(dummy_class.send(:strength_of_shill, current_price: current_price, data: weak_data))
                .to eq(30)
            end
          end
        end

        describe 'strength_of_individual_shill' do
          let(:short_unix_length) { 1_323_213 }
          let(:long_unix_length) { 13_232_130 }
          let(:base_percentage_increase) { 130.0 }

          context 'with short unix length' do
            it 'returns a higher score' do
              expect(dummy_class.send(:strength_of_individual_shill,
                                      unix_length: short_unix_length,
                                      base_percentage_increase: base_percentage_increase)).to eq(18)
            end
          end

          context 'when long unix length' do
            it 'returns a lower score' do
              expect(dummy_class.send(:strength_of_individual_shill,
                                      unix_length: long_unix_length,
                                      base_percentage_increase: base_percentage_increase)).to eq(16)
            end
          end
        end
      end
    end
  end
end
