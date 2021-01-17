# frozen_string_literal: true

require_relative '../../lib/palantir'

describe Palantir::Analyzer::Indicators do
  before do
    stub_const('ENV', 'TEST' => 'true')
  end

  describe 'analysis_as_hash' do
    let(:short_term) { [*1...20] }
    let(:long_term) do
      [
        {
          'Date' => '2020-01-02',
          'Open' => 84.900002,
          'High' => 86.139999,
          'Low' => 84.342003,
          'Close' => 86.052002,
          'Adj Close' => 86.052002,
          'Volume' => 47_660_500
        },
        {
          'Date' => '2020-01-03',
          'Open' => 88.099998,
          'High' => 90.800003,
          'Low' => 87.384003,
          'Close' => 88.601997,
          'Adj Close' => 88.601997,
          'Volume' => 88_892_500
        }
      ] * 10
    end
    let(:ticker) { 'PLTR' }
    let(:expected_output) do
      {
        simple_moving_average: 10,
        exponential_moving_average: 0.18455,
        ticker: 'PLTR',
        relative_strength_index: {
          rsi_step_one: 100.0,
          rsi_step_two: 100.0,
          current: 88.601997,
          sentiment: :oversold
        }
      }
    end

    before do
      allow(::Palantir::Database).to receive(:get_var).and_return([[]])
      allow(::Palantir::Database).to receive(:save_var)
    end

    it 'returns the expected hash' do
      expect(described_class.analysis_as_hash(short_term: short_term, long_term: long_term,
                                              ticker: ticker)).to eq(expected_output)
    end
  end
end
