# frozen_string_literal: true

module Palantir
  module Models
    class Base
      attr_reader :table

      def initialize(table: nil)
        @table = table
      end

      def attributes
        raise integrity_error(message: 'Table does not exist. Please run your migrations.') \
          unless table_exists?

        raise integrity_error(message: 'Your database is out of sync with your models. Please re-run migrations.') \
          unless column_names.are?(attributes: inherited_attributes)

        inherited_attributes
      end

      def migrate(environment: nil)
        raise integrity_error(message: 'Your migration has been run.') if table_exists?

        ::Palantir::Database.query(
          sql: 'CREATE TABLE IF NOT EXISTS ' \
          "#{table}_#{environment} " \
          "(#{inherited_attributes.join(' varchar, ')} varchar)",
        )
      end

      def clear(environment: nil)
        raise integrity_error(message: 'You cannot clear this table as it does not exist.') \
          unless table_exists?

        ::Palantir::Database.query(sql: "DELETE FROM #{table}_#{environment}")
      end

      def save(data: nil, environment: nil)
        return unless data.is_a? Hash
        raise integrity_error(message: 'You have tried inserting keys that do not exist in the table.') \
          unless column_names.are?(attributes: data.keys)

        ::Palantir::Database.query(
          sql: "INSERT INTO #{table}_#{environment} " \
               "(#{data.keys.join(', ')}) " \
               "VALUES ('#{data.values.join("', '")}')",
        )
      end

      def select(values: [], selector_column: nil, selector: nil, environment: nil)
        return unless values.is_a? Array
        raise integrity_error(message: 'You have tried selecting keys that do not exist in the table.') \
          unless column_names.names_for_comparison.include?(selector_column)

        ::Palantir::Database.query(
          sql: "SELECT #{values.join(', ')} " \
               "FROM #{table}_#{environment} " \
               "WHERE #{selector_column} = '#{selector}'",
          values: true,
        )
      end

      private

      def integrity_error(message: nil)
        ::Palantir::Exceptions::DatabaseIntegrityError.new(logger: ::Palantir.logger, message: message)
      end

      def inherited_attributes
        self.class::ATTRIBUTES
      end

      def table_exists?
        ::Palantir::Database.query(sql: "SELECT EXISTS(
          SELECT FROM information_schema.tables WHERE table_name = '#{table}'
        )", values: true).flatten.first == 't'
      end

      def column_names
        ColumnNames.new(table: table)
      end
    end

    class ColumnNames
      attr_reader :table, \
                  :environment

      def initialize(table: nil)
        @table = table
        @environment = 'test'
      end

      def are?(attributes: nil)
        names_for_comparison == attributes.join
      end

      def names
        # specific syntax for postgres
        ::Palantir::Database.query(sql: "SELECT json_object_keys(
          to_json(
            json_populate_record(
              NULL::#{table}_#{environment}, '{}'::JSON
            )
          )
        )", values: true).flatten
      end

      def names_for_comparison
        names.map(&:values).flatten.join
      end
    end
  end
end
