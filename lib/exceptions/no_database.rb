# frozen_string_literal: true

module Palantir
  module Exceptions
    class NoDatabase < StandardError
      def initialize(logger: nil, conn_params: nil)
        message = 'Database does not exist.' \
                  " Connection parameters: #{conn_params.to_json}"
        logger.write(time: Time.now, message: message)
        super(message)
      end
    end
  end
end
