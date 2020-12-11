# frozen_string_literal: true

%w[
  clients
  exceptions
  extractors
  utility
].each do |dir|
  Dir.glob("./lib/#{dir}/*.rb").sort.each { |file| require file }
end

require_relative 'analyzer'
require_relative 'logger'
require_relative 'runner'

module Palantir
  module_function

  LOG_FILE_PATH = 'tmp/core_log.txt'
  TICKER_CONFIG_FILE = 'config/ticker_config.yml'

  def logger
    ::Palantir::Logger.new(
      file_path: LOG_FILE_PATH,
    )
  end
end
