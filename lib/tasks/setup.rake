# frozen_string_literal: true

require 'yaml'

desc 'Setting up ticker file'
namespace :palantir do
  task :setup do
    stable_stocks = %w[
      S&P500
      TSLA
      RR
    ]
    write_to_config stable_stocks
  end
end

def write_to_config(tickers)
  File.open(::Palantir::TICKER_CONFIG_FILE, 'w') { |file| file.write(tickers.to_yaml) }
end
