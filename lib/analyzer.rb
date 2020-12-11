# frozen_string_literal: true

require 'parallel'

Dir.glob('./lib/analyzer/*.rb').sort.each { |file| require file }

module Palantir
  class Analyzer
    attr_reader :tickers, \
                :run_wild, \
                :rumour_ratio, \
                :concurrency

    def initialize(tickers: nil, run_wild: nil, rumour_ratio: nil, concurrency: nil)
      # VERSION ONE
      #
      # ANY ticker that is defined by user does not have a RISK/RUMOUR ratio
      # associated with them
      # Take number of defined tickers and calculated required amount against rumour_ratio
      # to equal one
      # if rumour_ratio undefined, assume an amount
      # run_wild only works with rumour_ratio being set
      # analyze reddit throughout runs for shilling and use them for rumours
      # analyze trends and notify stdout of any BUY or SELL trends
      @tickers = tickers
      @run_wild = run_wild
      @rumour_ratio = rumour_ratio
      @concurrency = concurrency
    end

    def analyze!
      Parallel.each(tickers, in_threads: concurrency) do |ticker|
        analyze(ticker: ticker)
      end
      # search for more tickers if needed
    end

    private

    def analyze(ticker: nil)
      ::Palantir::Clients::GoogleClient.get_ticker(ticker)
      # store in database
      # analyze trend
      # write to stdout
    end
  end
end
