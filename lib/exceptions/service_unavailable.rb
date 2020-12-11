# frozen_string_literal: true

module Palantir
  module Exceptions
    class ServiceUnavailable < StandardError
      def initialize(error: nil, url: nil, query: nil, logger: nil)
        message = "Error: #{error} calling url: #{url}" \
                  "with: #{query || 'none'}"
        logger.write(time: Time.now, message: message)
        super(message)
      end
    end
  end
end
