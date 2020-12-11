# frozen_string_literal: true

module Palantir
  module Exceptions
    class NoTickers < StandardError
      def initialize(logger: nil)
        message = 'No tickers defined for the cycle. ' \
                  'You must define a ticker as per the instructions'
        logger.write(time: Time.now, message: message)
        super(message)
      end
    end
  end
end
