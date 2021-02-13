# frozen_string_literal: true

module Palantir
  module Exceptions
    class DatabaseIntegrityError < StandardError
      def initialize(logger: nil, message: nil)
        logger.write(time: Time.now, message: message)
        super(message)
      end
    end
  end
end
