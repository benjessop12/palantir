# frozen_string_literal: true

require 'time'
require 'timecop'

require_relative '../lib/palantir'

describe Palantir::Analyzer do
  let(:base_dummy_class) { described_class.new(tickers: 'PLTR', interval: 60) }

  describe 'analyze_data' do
    let(:historic_data) { [%w[1 2021-01-01]] }
    let(:ticker) { 'PLTR' }
    let(:stub_json) { { stub: 'json' }.to_json }

    before do
      allow(base_dummy_class).to receive(:warn)
      allow(::Palantir::Analyzer::Indicators).to receive(:analysis_as_json).and_return(stub_json)
    end

    it 'takes an array of arrays with ticker values at timepoints and performs analysis on them and logs to stdout' do
      base_dummy_class.send(:analyze_data, historic_data: historic_data, ticker: ticker)
      expect(base_dummy_class).to have_received(:warn).with(stub_json)
    end
  end

  describe 'outside_defined_run_constraint' do
    context 'when run_until is defined' do
      before do
        Timecop.freeze(Time.local(2021, 1, 1, 12, 0, 0))
      end

      after do
        Timecop.return
      end

      context 'defined time is in the future' do
        let(:run_until) { Time.parse('12:02') }
        let(:dummy_class) { described_class.new(run_until: run_until) }

        it 'returns false' do
          expect(dummy_class.send(:outside_defined_run_constraint)).to eq(false)
        end
      end

      context 'defined time is in the past' do
        let(:run_until) { Time.parse('11:59') }
        let(:dummy_class) { described_class.new(run_until: run_until) }

        it 'returns true' do
          expect(dummy_class.send(:outside_defined_run_constraint)).to eq(true)
        end
      end

      context 'defined time is infinity' do
        let(:run_until) { Float::INFINITY }
        let(:dummy_class) { described_class.new(run_until: run_until) }

        it 'returns true' do
          expect(dummy_class.send(:outside_defined_run_constraint)).to eq(false)
        end
      end
    end

    context 'when run until is not defined' do
      it 'returns false' do
        expect(base_dummy_class.send(:outside_defined_run_constraint)).to eq(false)
      end
    end
  end

  describe 'threads_for_rumour_analysis' do
    let(:tickers) { %w[PLTR NIO TSLA] }

    context 'when given tickers but run_wild and rumour_ratio is nil/false' do
      it 'returns tickers' do
        expect(base_dummy_class.send(:threads_for_rumour_analysis, tickers: tickers, run_wild: false,
                                                                   rumour_ratio: nil)).to eq(tickers)
      end
    end

    context 'when given tickers and run_wild but rumour_ratio is nil/false' do
      it 'returns tickers' do
        expect(base_dummy_class.send(:threads_for_rumour_analysis, tickers: tickers, run_wild: true,
                                                                   rumour_ratio: nil)).to eq(tickers)
      end
    end

    context 'when given tickers and run_wild and rumour_ratio' do
      context 'when the rumour ratio is 0.1' do
        it 'returns one search_for element with the tickers' do
          expect(base_dummy_class.send(:threads_for_rumour_analysis, tickers: tickers, run_wild: true,
                                                                     rumour_ratio: 0.1)).to eq(
                                                                       tickers << 'SEARCH_FOR',
                                                                     )
        end
      end

      context 'when the rumour ratio is 0.5' do
        it 'returns three search_for elements with the tickers' do
          expect(base_dummy_class.send(:threads_for_rumour_analysis, tickers: tickers, run_wild: true,
                                                                     rumour_ratio: 0.1)).to eq(
                                                                       tickers << (%w[SEARCH_FOR] * 3),
                                                                     )
        end
      end

      context 'when the rumour ratio is 0.9' do
        it 'returns six search_for elements with the tickers' do
          expect(base_dummy_class.send(:threads_for_rumour_analysis, tickers: tickers, run_wild: true,
                                                                     rumour_ratio: 0.1)).to eq(
                                                                       tickers << (%w[SEARCH_FOR] * 6),
                                                                     )
        end
      end
    end
  end
end
