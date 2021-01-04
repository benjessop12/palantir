# frozen_string_literal: true

require_relative '../../lib/palantir'

describe Palantir::Analyzer::Indicators do
  describe 'analysis_as_json' do
    let(:input_data) { [*1...20] }
    let(:ticker) { 'PLTR' }
    let(:expected_output) do
      {
        simple_moving_average: 10,
        exponential_moving_average: 0.18455,
        ticker: 'PLTR',
        relative_strength_index: {
          rsi_step_one: 100.0,
          rsi_step_two: 100.0,
          current: 19,
          sentiment: 'oversold'
        }
      }.to_json
    end

    before do
      allow(::Palantir::Database).to receive(:get_var).and_return([[]])
      allow(::Palantir::Database).to receive(:save_var)
    end

    it 'returns the expected json' do
      expect(described_class.analysis_as_json(input_data: input_data, ticker: ticker)).to eq(expected_output)
    end
  end
end
