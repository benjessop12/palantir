# frozen_string_literal: true

module Palantir
  module Models
    class Reports < Base
      ATTRIBUTES = %w[
        ticker
        open
        high
        low
        moving_average
        relative_strength_index
        buy_or_sell
        bottoms
        tops
        initial_hour_movement
        power_hour_movement
        date
      ].freeze

      def initialize
        super(table: 'reports')
      end

      def report_by(date: nil)
        select(
          values: %w[*],
          selector_column: 'date',
          selector: date,
          environment: 'test',
        )
      end
    end
  end
end
