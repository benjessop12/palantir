# frozen_string_literal: true

module Palantir
  module HelperFunctions
    module_function

    def median_of(array_of_ticker_data: nil)
      return nil if array_of_ticker_data.empty?

      sorted = array_of_ticker_data.sort
      len = array_of_ticker_data.length
      (sorted[(len - 1) / 2] + sorted[len / 2]) / 2.0
    end
  end
end
