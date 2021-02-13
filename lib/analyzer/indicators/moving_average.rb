# frozen_string_literal: true

module Palantir
  class Analyzer
    class Indicators
      class MovingAverage
        include ::Palantir::HelperFunctions

        INCREMENT = 1
        SEGMENT = 2

        attr_reader :input_data, \
                    :ticker,
                    :count,
                    :sum

        def initialize(input_data: nil, ticker: nil)
          @input_data = input_data
          @ticker = ticker
          @count = input_data&.count.to_i
          @sum = input_data&.sum.to_i
        end

        def simple
          sum / count
        end

        def exponential
          exponential_primer(scope: :current) + previous_ema * weighting
        end

        private

        def exponential_primer(scope: nil)
          (
            data(scope: scope) * (
              smooth_factor / (INCREMENT + count)
            )
          )
        end

        def previous_ema
          if first_time?
            simple
          else
            mark_ticker(value: exponential_primer(scope: :former))
          end
        end

        def first_time?
          in_db = Palantir::Models::Variables.new.get_var name: ticker
          !in_db.flatten.empty?
        end

        def mark_ticker(value: nil)
          Palantir::Models::Variables.new.save_var name: ticker, value: value
          value
        end

        def weighting
          (
            INCREMENT - (
              smooth_factor / (INCREMENT + count)
            )
          )
        end

        def smooth_factor
          SEGMENT / (count + INCREMENT).to_f
        end

        def data(scope: nil)
          case scope
          when nil
            input_data
          when :current
            input_data.last
          when :former
            input_data[(count - (INCREMENT * 2))...(count - INCREMENT)].first
          end
        end
      end
    end
  end
end
