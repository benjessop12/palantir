# frozen_string_literal: true

require 'parallel'

Dir.glob('./lib/analyzer/*.rb').sort.each { |file| require file }

module Palantir
  class Analyzer
    SEARCH_NODE = 'SEARCH_FOR'
    ELEMENTS = 2

    attr_reader :runners, \
                :run_wild, \
                :rumour_ratio, \
                :concurrency, \
                :interval, \
                :run_until

    attr_accessor :logger

    def initialize(tickers: nil, run_wild: nil, rumour_ratio: nil, concurrency: nil, interval: nil, run_until: nil)
      @runners = threads_for_rumour_analysis(tickers: tickers, run_wild: run_wild, rumour_ratio: rumour_ratio)
      @concurrency = concurrency
      @interval = interval
      @logger = ::Palantir.logger
      @run_until = run_until
    end

    def analyze!
      Parallel.each(runners, in_threads: concurrency) do |ticker|
        ticker == SEARCH_NODE ? search_for_information(defined_tickers: runners) : analyze(ticker: ticker)
      end
    end

    private

    def analyze(ticker: nil)
      run_with_constraints do
        current_data = ::Palantir::Clients::GoogleClient.get_ticker(ticker)
        ::Palantir::Database.save_var name: ticker, value: current_data[:value], at_date: current_data[:request_time]
        # TODO: serious oom issues will arise if the below line is not fixed
        analyze_data historic_data: ::Palantir::Database.get_var(name: ticker), ticker: ticker
        # here is where we see a need for a queue
        # in terms of good design
        # sleeping in any ruby script is bad
        sleep interval
      end
    end

    def analyze_data(historic_data: nil, ticker: nil)
      ticker_values_short_term = historic_data.map(&:first).map(&:to_f).reject(&:zero?)
      ticker_values_long_term = ::Palantir::Clients::YahooFinance.new(stock_code: ticker,
                                                                      start_date: date[:start],
                                                                      end_date: date[:end]).collect_data
      analysis_as_hash = Palantir::Analyzer::Indicators.analysis_as_hash(short_term: ticker_values_short_term,
                                                                         long_term: ticker_values_long_term,
                                                                         ticker: ticker)
      warn analysis_as_hash.to_s
      logger.write(time: Time.now, message: analysis_as_hash)
    end

    def date
      {
        start: (Date.today - 90).strftime('%Y-%m-%d'),
        end: (Date.today).strftime('%Y-%m-%d')
      }
    end

    def search_for_information(defined_tickers: [])
      # default HIGH for now, since subreddit investing assertions are too weak
      analysis = Palantir::Extractors::Reddit.new(risk_level: 'HIGH')
      analysis.extract_data
      # if ambiguous / no best option, then what
      analyze ticker: analysis.best_option(defined_tickers: defined_tickers)
    end

    def run_with_constraints(&block)
      loop do
        block.call
        break if outside_defined_run_constraint
      end
    end

    def outside_defined_run_constraint
      return false unless run_until

      run_until != Float::INFINITY && (Time.now.to_i > run_until.to_i)
    end

    def threads_for_rumour_analysis(tickers: nil, run_wild: nil, rumour_ratio: nil)
      return tickers if run_wild.nil? || rumour_ratio.nil?

      search_thread_count = (tickers.count * ELEMENTS * rumour_ratio).to_i
      search_thread_count = 1 if search_thread_count.zero?
      tickers + [SEARCH_NODE] * search_thread_count
    end
  end
end
