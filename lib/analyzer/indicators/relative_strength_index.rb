# frozen_string_literal: true

module Palantir
  class Analyzer
    class Indicators
      class RelativeStrengthIndex
        include ::Palantir::HelperFunctions

        TOP_STRENGTH_LEVEL = 100.00
        STRENGTH_INCREMENT = 1.00
        SEGMENT = 2
        MINIMUM_NUMBER_OF_ELEMENTS = 14

        attr_reader :input_data, \
                    :count,
                    :trimmed_count

        attr_accessor :price_changes

        def initialize(input_data: nil)
          @input_data = input_data
          @count = input_data&.count.to_i
          @trimmed_count = count - STRENGTH_INCREMENT
          @price_changes = []
          raise_unless_expected_data
          calculate_trends
        end

        def analyze
          {
            rsi_step_one: rsi_step_one,
            rsi_step_two: rsi_step_two,
            current: input_data&.last,
            sentiment: sentiment
          }
        end

        private

        def rsi_step_one
          with_relative_strength do
            average(type: :gain) / average(type: :loss)
          end
        end

        def rsi_step_two
          with_relative_strength do
            ((average(type: :gain, scope: :previous) * trimmed_count) + average(type: :gain, scope: :current)) \
              / ((average(type: :loss, scope: :previous) * trimmed_count) + average(type: :loss, scope: :current))
          end
        end

        def calculate_trends(scope: nil)
          data(scope: scope, array: input_data).each_cons(SEGMENT).select do |former, subsequent|
            price_changes << (subsequent - former)
          end
        end

        def average(type: nil, scope: nil)
          case type
          when :gain
            average_of(array_of_ticker_data: data(scope: scope, array: price_changes).map do |pc|
                                               pc.positive? ? pc : 0
                                             end)
          when :loss
            average_of(array_of_ticker_data: data(scope: scope, array: price_changes).map do |pc|
                                               pc.negative? ? pc.abs : 0
                                             end)
          end
        end

        def data(scope: nil, array: nil)
          case scope
          when nil
            array
          when :current
            array.last(SEGMENT)
          when :previous
            array[0...-SEGMENT]
          end
        end

        def sentiment
          return :overbought if rsi_step_two > 70
          return :oversold if rsi_step_two < 30

          :neutral
        end

        def raise_unless_expected_data
          return unless count < MINIMUM_NUMBER_OF_ELEMENTS

          raise ::Palantir::Exceptions::IncorrectData.new(
            logger: ::Palantir.logger,
            data_received: input_data,
            expectation: 'Array with at least 14 elements',
          )
        end

        def with_relative_strength(&block)
          TOP_STRENGTH_LEVEL - (
            TOP_STRENGTH_LEVEL / (
              STRENGTH_INCREMENT +
                block.call

            )
          )
        end
      end
    end
  end
end
