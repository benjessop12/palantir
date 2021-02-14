# frozen_string_literal: true

module Palantir
  module HelperFunctions
    module_function

    def average_of(array_of_ticker_data: nil)
      return nil if array_of_ticker_data.empty?

      array_of_ticker_data.inject(0, :+) / array_of_ticker_data.size.to_f
    end
  end
end
