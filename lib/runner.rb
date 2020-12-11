# frozen_string_literal: true

require 'yaml'

module Palantir
  module Runner
    extend self

    DEFAULT_CONCURRENCY = 5

    def run!
      raise_undefined_config unless defined_tickers?
      tickers = collect_tickers
      ::Palantir::Analyzer.new(
        tickers: tickers,
        run_wild: run_wild,
        rumour_ratio: rumour_ratio,
        concurrency: concurrency,
      ).analyze!
    end

    private

    def collect_tickers
      return tickers_from_env + tickers_from_config unless tickers_from_config.nil?

      tickers_from_env
    end

    def concurrency
      return DEFAULT_CONCURRENCY if ENV['CONCURRENCY'].nil?
      return nproc if nproc < ENV['CONCURRENCY'].to_i

      ENV['CONCURRENCY'].to_i
    end

    def nproc
      val = `echo $(ulimit -u)`.gsub(/\n/, '')
      val == 'unlimited' ? Float::INFINITY : val
    end

    def defined_tickers?
      !tickers_from_env.empty? || !tickers_from_config.nil? || run_wild
    end

    def tickers_from_env
      ENV['TICKERS'].nil? ? [] : ENV['TICKERS'].split(',')
    end

    def tickers_from_config
      YAML.safe_load(File.open(::Palantir::TICKER_CONFIG_FILE))
    rescue Errno::ENOENT
      nil
    end

    def run_wild
      ENV['RUN_WILD']&.downcase == 'true'
    end

    def rumour_ratio
      defined_ratio = ENV['RUMOUR'].nil? ? return : ENV['RUMOUR']
      raise_incorrect_rumour(defined_ratio) unless defined_ratio.to_f < 1 && valid_float?
      defined_ratio.to_f
    end

    def valid_float?
      return false if ENV['RUMOUR'].nil?

      begin Float(ENV['RUMOUR'])
            true
      rescue StandardError
        false
      end
    end

    def raise_undefined_config
      raise ::Palantir::Exceptions::NoTickers.new(
        logger: ::Palantir.logger,
      )
    end

    def raise_incorrect_rumour(rumour)
      raise ::Palantir::Exceptions::IncorrectRumour.new(
        logger: ::Palantir.logger,
        rumour: rumour,
      )
    end
  end
end
