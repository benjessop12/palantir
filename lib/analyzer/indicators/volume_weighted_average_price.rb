# frozen_string_literal: true

module Palantir
  class Analyzer
    class Indicators
      class VolumeWeightedAveragePrice
        # Q: what is the class going to receive
        # A: an array of datum
        # Q: What does the class return
        # A: WARN if price is below or above VWAP, movement and if there are new low/high points

        # Get the average price of the stock traded at the first five-minute period of the day
        # multiply this by the volume of that period
        # devide the result by the volumne of the period
        # for each period (define) add the PV value to the prior values and devide by the volume to that point

        # basic: buy below VWAP and sell above it
        def initialize(input_data: nil)
          # dostuff
        end
      end
    end
  end
end
