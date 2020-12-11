# frozen_string_literal: true

module Palantir
  module Exceptions
    class IncorrectData < StandardError
      def initialize(logger: nil, data_received: nil, expectation: nil)
        message = "Incorrect data. Expected: #{expectation}. " \
                  "Got: #{data_received}"
        logger.write(time: Time.now, message: message)
        super(message)
      end
    end
  end
end
