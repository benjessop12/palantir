# frozen_string_literal: true

Dir.glob('./lib/analyzer/indicators/*.rb').sort.each { |file| require file }

module Palantir
  class Analyzer
    class Indicators
      class << self
        def analysis_as_json(input_data: nil, ticker: nil)
          moving_average = MovingAverage.new(input_data: input_data, ticker: ticker)
          data = {
            simple_moving_average: moving_average.simple,
            exponential_moving_average: moving_average.exponential,
            ticker: ticker
          }
          data.merge!(relative_strength_index: RelativeStrengthIndex.new(input_data: input_data).analyze) \
            if input_data.count >= RelativeStrengthIndex::MINIMUM_NUMBER_OF_ELEMENTS
          data.to_json
        end
      end
    end
  end
end
