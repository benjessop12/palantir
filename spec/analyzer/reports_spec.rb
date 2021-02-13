# frozen_string_literal: true

require_relative '../../lib/palantir'

require 'timecop'

describe ::Palantir::Analyzer::Reports do
  let(:ticker) { 'PLTR' }
  let(:data_short) { [*5..10] }
  let(:data_long) { [*1..10] }
  let(:analysis) do
    {
      simple_moving_average: 1,
      exponential_moving_average: 2,
      ticker: ticker,
      relative_strength_index: {
        rsi_step_one: 3,
        rsi_step_two: 4,
        current: 5,
        sentiment: :neutral
      }
    }
  end
  let(:model_instance) { ::Palantir::Models::Reports.new }
  let(:local_time) { Time.local(2021, 1, 1, 0, 0, 0) }

  before do
    Timecop.freeze(local_time)
    allow(Date).to receive(:today).and_return(local_time)
  end

  after do
    Timecop.return
  end

  describe 'save!' do
    let(:expected_data_hash) do
      {
        data: {
          ticker: ticker,
          open: 5,
          high: 10,
          low: 5,
          moving_average: 2,
          relative_strength_index: 4,
          buy_or_sell: :neutral,
          bottoms: 1,
          tops: 1,
          initial_hour_movement: 5,
          power_hour_movement: 5,
          date: '2021-01-01'
        },
        environment: 'test'
      }
    end

    before do
      allow(::Palantir::Models::Reports).to receive(:new).and_return(model_instance)
      allow(model_instance).to receive(:save)
    end

    it 'sends the correct data to be saved in the report model' do
      described_class.new(ticker: ticker, data_short: data_short, data_long: data_long, analysis: analysis)
                     .save!
      expect(model_instance).to have_received(:save).with(expected_data_hash).once
    end
  end

  describe 'movement' do
    let(:described_instance) { described_class.new }

    context 'when the close was higher than the open' do
      let(:data) { [1, 2, 3] }

      it 'returns the correct data' do
        expect(described_instance.send(:movement, data: data)).to eq(2)
      end
    end

    context 'when the closer was lower than the open' do
      let(:data) { [3, 2, 1] }

      it 'returns the correct data' do
        expect(described_instance.send(:movement, data: data)).to eq(-2)
      end
    end

    context 'when the close was the same as the open' do
      let(:data) { [1, 2, 1] }

      it 'returns 0' do
        expect(described_instance.send(:movement, data: data)).to eq(0)
      end
    end
  end
end
