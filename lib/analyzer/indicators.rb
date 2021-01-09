# frozen_string_literal: true

Dir.glob('./lib/analyzer/indicators/*.rb').sort.each { |file| require file }

module Palantir
  class Analyzer
    class Indicators
      class << self
        def analysis_as_hash(input_data: nil, ticker: nil)
          moving_average = MovingAverage.new(input_data: input_data, ticker: ticker)
          analysis_data = {
            simple_moving_average: moving_average.simple,
            exponential_moving_average: moving_average.exponential,
            ticker: ticker
          }
          analysis_data.merge!(relative_strength_index: RelativeStrengthIndex.new(input_data: input_data).analyze) \
            if input_data.count >= RelativeStrengthIndex::MINIMUM_NUMBER_OF_ELEMENTS
          analysis_data
        end
      end
    end
  end
end
