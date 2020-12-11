# frozen_string_literal: true

module Palantir
  module Exceptions
    class NotFound < StandardError
      def initialize(end_point: nil, status_code: nil)
        message = "Error requesting #{end_point}." \
                  "Status_code: #{status_code}"
        logger.write(time: Time.now, message: message)
        super(message)
      end
    end
  end
end
