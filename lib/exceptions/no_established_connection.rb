# frozen_string_literal: true

module Palantir
  module Exceptions
    class NoEstablishedConnection < StandardError
      def initialize(logger: nil, conn_params: nil)
        message = 'Could not establish a connection to the database.' \
                  " Connection parameters: #{conn_params.to_json}"
        logger.write(time: Time.now, message: message)
        super(message)
      end
    end
  end
end
