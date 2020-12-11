# frozen_string_literal: true

module Palantir
  class Analyzer
    class Indicators
      class MovingAverage
        include ::Palantir::HelperFunctions

        # to create a series of averages of different subsets of the full dataset
        # is a mitigator for short-term fluctiations in ticker price

        # include a method to indicate lag
        # a.k.a a long lookback period has more lag
        # which is not necessarily a bad thing
        # it just means the forecast might take longer to hit
        # that a short sample
        # the shorter the time span the more sensitive
        # it is to price changes

        # simple moving average
        # arithmetic mean of given set of values
        # array.sum / array.count

        # exponential moving average
        # gives more weight to recent prices
        # smoothing factor =
        #   [2 / (number of days + 1)]
        # EMA = value_today * \
        #   (smoothing / (1 + number of days)) + \
        #   EMA yesterday * [1 - *(smoothing / (1 + number of days))]

        INCREMENT = 1
        SEGMENT = 2

        attr_reader :input_data, \
                    :count, \
                    :sum

        def initialize(input_data: nil)
          @input_data = input_data
          @count = input_data&.count.to_i
          @sum = input_data&.sum.to_i
        end

        private

        def simple
          sum / count
        end

        def exponential
          exponential_primer(scope: :current) + previous_ema * weighting
        end

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
            exponential_primer(scope: :former)
          end
        end

        def first_time?
          # do you have the data
          # make a db accessor
          # get_var last_exponential helper
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
