# frozen_string_literal: true

require 'pg'
require 'yaml'

Dir.glob('./lib/database/*.rb').sort.each { |file| require file }

module Palantir
  module Database
    module_function

    extend Connection

    def save_var(name: nil, value: nil, at_date: nil)
      sql_format = "INSERT INTO #{table_name}(name, value, at_date, created_at) VALUES ('%s', '%s', '%s', '%s')"
      date = at_date.nil? ? Time.now : at_date
      sql = format(sql_format, name, value, date.strftime('%Y-%m-%d'), Time.now.strftime('%Y-%m-%d'))
      query(sql: sql)
    end

    def get_var(name: nil)
      sql_format = "SELECT value, at_date FROM #{table_name} WHERE name = '%s'"
      sql = format(sql_format, name)
      query(sql: sql, values: true)
    end

    def query(sql: nil, values: nil)
      query = postgresql_connection(config: dbconfig).execute(sql: sql)
      values ? query.values : query
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
