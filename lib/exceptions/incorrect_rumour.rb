# frozen_string_literal: true

module Palantir
  module Exceptions
    class IncorrectRumour < StandardError
      def initialize(logger: nil, rumour: nil)
        message = 'Rumour must be a float and less than 1. ' \
                  "Attempted to pass #{rumour} as the rumour."
        logger.write(time: Time.now, message: message)
        super(message)
      end
    end
  end
end
