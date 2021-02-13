# frozen_string_literal: true

require 'time'
require 'timecop'
require 'webmock'

require_relative '../lib/palantir'

describe Palantir::Analyzer do
  include WebMock::API

  let(:base_dummy_class) { described_class.new(tickers: 'PLTR', interval: 60) }

  describe 'save_report' do
    context 'when about to report instance variable is false' do
      before do
        base_dummy_class.instance_variable_set(:@about_to_report, false)
      end

      it 'returns nil' do
        expect(base_dummy_class.send(:save_report)).to eq(nil)
      end
    end

    context 'when about to report instance variable is true' do
      let(:report_instance) { ::Palantir::Analyzer::Reports.new }

      before do
        allow(::Palantir::Analyzer::Reports).to receive(:new).and_return(report_instance)
        allow(::Palantir::Database).to receive(:query).and_return([{ key_one: 'date' }])
        allow(report_instance).to receive(:save!)
        base_dummy_class.instance_variable_set(:@about_to_report, true)
        base_dummy_class.instance_variable_set(:@runners, [1])
      end

      it 'saves the analysis values to the database' do
        base_dummy_class.send(:save_report)
        expect(report_instance).to have_received(:save!).once
      end
    end
  end

  describe 'in_reporting_timeline' do
    after do
      Timecop.return
    end

    context 'when the time is within the REPORTING_RANGE' do
      let(:time_in_range) { Time.local(2021, 1, 1, 21, 1, 0) }

      before do
        base_dummy_class.instance_variable_set(:@about_to_report, false)
        Timecop.freeze(time_in_range)
      end

      context 'when the daily report has run' do
        before do
          allow(DateTime).to receive(:now).and_return(time_in_range)
          base_dummy_class.instance_variable_set(:@last_day_of_report, time_in_range)
        end

        it 'does not set the about to report variable to true' do
          base_dummy_class.send(:in_reporting_timeline)
          expect(base_dummy_class.instance_variable_get(:@about_to_report)).to eq(false)
        end
      end

      context 'when the daily report has not run' do
        before do
          base_dummy_class.instance_variable_set(:@last_day_of_report, Time.local(2020, 12, 31, 21, 1, 0))
        end

        it 'sets the about to report variable to true' do
          base_dummy_class.send(:in_reporting_timeline)
          expect(base_dummy_class.instance_variable_get(:@about_to_report)).to eq(true)
        end
      end
    end

    context 'when the time is not within the REPORTING_RANGE' do
      before do
        Timecop.freeze(Time.local(2021, 1, 1, 0, 0, 0))
        base_dummy_class.instance_variable_set(:@about_to_report, true)
      end

      it 'sets the about to report variable to false' do
        base_dummy_class.send(:in_reporting_timeline)
        expect(base_dummy_class.instance_variable_get(:@about_to_report)).to eq(false)
      end
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
                                                                       tickers + %w[SEARCH_FOR],
                                                                     )
        end
      end

      context 'when the rumour ratio is 0.5' do
        it 'returns three search_for elements with the tickers' do
          expect(base_dummy_class.send(:threads_for_rumour_analysis, tickers: tickers, run_wild: true,
                                                                     rumour_ratio: 0.5)).to eq(
                                                                       tickers + %w[SEARCH_FOR] * 3,
                                                                     )
        end
      end

      context 'when the rumour ratio is 0.9' do
        it 'returns six search_for elements with the tickers' do
          expect(base_dummy_class.send(:threads_for_rumour_analysis, tickers: tickers, run_wild: true,
                                                                     rumour_ratio: 0.9)).to eq(
                                                                       tickers + %w[SEARCH_FOR] * 5,
                                                                     )
        end
      end
    end
  end

  describe 'date' do
    let(:expected_output) { { end: '2021-01-01', start: '2020-10-03' } }

    before do
      Timecop.freeze(Time.local(2021, 1, 1))
    end

    after do
      Timecop.return
    end

    it 'returns the expected time differences for stock analysis' do
      expect(base_dummy_class.send(:date)).to eq(expected_output)
    end
  end
end
