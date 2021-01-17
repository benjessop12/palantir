# frozen_string_literal: true

Dir.glob('./lib/analyzer/indicators/*.rb').sort.each { |file| require file }

module Palantir
  class Analyzer
    class Indicators
      class << self
        def analysis_as_hash(short_term: nil, long_term: nil, ticker: nil)
          moving_average = MovingAverage.new(input_data: short_term, ticker: ticker)
          analysis_data = {
            simple_moving_average: moving_average.simple, exponential_moving_average: moving_average.exponential,
            ticker: ticker
          }
          long_term_data = long_term.map { |e| e['Close'] }
          if long_term_data.count >= RelativeStrengthIndex::MINIMUM_NUMBER_OF_ELEMENTS
            analysis_data.merge!(relative_strength_index: RelativeStrengthIndex.new(input_data: long_term_data).analyze)
          end
          analysis_data
        end
      end
    end
  end
end
