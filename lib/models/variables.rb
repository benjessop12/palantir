# frozen_string_literal: true

module Palantir
  module Models
    class Variables < Base
      ATTRIBUTES = %w[
        name
        value
        at_date
        created_at
      ].freeze

      def initialize
        super(table: 'variables')
      end

      def save_var(name: nil, value: nil, at_date: nil)
        date = at_date.nil? ? Time.now : at_date
        data = {
          name: name,
          value: value,
          at_date: date,
          created_at: Time.now.strftime('%Y-%m-%d')
        }
        save(data: data, environment: 'test')
      end

      def get_var(name: nil)
        get_vars(name: name).first
      end

      def get_vars(name: nil)
        select(
          values: %w[value at_date],
          selector_column: 'name',
          selector: name,
          environment: 'test',
        )
      end
    end
  end
end
