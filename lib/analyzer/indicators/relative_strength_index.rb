# frozen_string_literal: true

module Palantir
  class Analyzer
    class Indicators
      class RelativeStrengthIndex
        include ::Palantir::HelperFunctions

        TOP_STRENGTH_LEVEL = 100
        STRENGTH_INCREMENT = 1
        SEGMENT = 2
        MINIMUM_NUMBER_OF_ELEMENTS = 14

        attr_reader :input_data, \
                    :count,
                    :trimmed_count,
                    :positive_gains,
                    :negative_trends

        def initialize(input_data: nil)
          @input_data = input_data
          @count = input_data&.count.to_i
          @trimmed_count = count - STRENGTH_INCREMENT
          @positive_gains = []
          @negative_trends = []
          raise_unless_expected_data
          warn("INPUT DATA: #{input_data}")
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

        def average_median_gain(scope: nil)
          data(scope: scope).each_cons(SEGMENT).select do |element, subsequent|
            positive_gains << if element < subsequent
                                get_percentage_leap(element, subsequent)
                              else
                                0
                              end
          end
          median_of array_of_ticker_data: positive_gains
        end

        def average_median_loss(scope: nil)
          data(scope: scope).each_cons(SEGMENT).select do |element, subsequent|
            negative_trends << if element > subsequent
                                 get_percentage_leap(element, subsequent)
                               else
                                 0
                               end
          end
          median_of array_of_ticker_data: negative_trends
        end

        def average(type: nil, scope: nil)
          case type
          when :gain
            average_median_gain(scope: scope) / count
          when :loss
            average_median_loss(scope: scope) / count
          end
        end

        def data(scope: nil)
          case scope
          when nil
            input_data
          when :current
            input_data.last(SEGMENT)
          when :previous
            input_data[0...-SEGMENT]
          end
        end

        def get_percentage_leap(first, last)
          ((last.to_f - first) / first) * TOP_STRENGTH_LEVEL
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
