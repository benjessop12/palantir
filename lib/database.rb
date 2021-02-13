# frozen_string_literal: true

require 'pg'
require 'yaml'

Dir.glob('./lib/database/*.rb').sort.each { |file| require file }

module Palantir
  module Database
    module_function

    extend Connection

    def query(sql: nil, values: nil)
      query = postgresql_connection(config: dbconfig).execute(sql: sql)
      values ? query.to_set.to_a : query
    end

    def dbconfig
      YAML.safe_load(File.open(::Palantir::DB_CONFIG_FILE))
    rescue Errno::ENOENT
      nil
    end

    def table_name
      return 'variables_test' if ENV['TEST']&.downcase == 'true'

      'variables'
    end
  end
end
