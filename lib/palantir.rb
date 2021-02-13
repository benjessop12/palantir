# frozen_string_literal: true

require_relative 'database'

%w[
  clients
  exceptions
  extractors
  models
  utility
].each do |dir|
  Dir.glob("./lib/#{dir}/*.rb").sort.each { |file| require file }
end

require_relative 'analyzer'
require_relative 'logger'
require_relative 'runner'

module Palantir
  module_function

  EMAIL_CONFIG_FILE = '/etc/ssmtp/ssmtp.conf'
  LOG_FILE_PATH = 'tmp/core_log.txt'
  TICKER_CONFIG_FILE = 'config/ticker_config.yml'
  DB_CONFIG_FILE = 'config/database.yml'

  def logger
    ::Palantir::Logger.new(
      file_path: LOG_FILE_PATH,
    )
  end
end
