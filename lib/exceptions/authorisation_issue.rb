# frozen_string_literal: true

module Palantir
  module Exceptions
    class AuthorisationIssue < StandardError
      def initialize(logger: nil)
        message = 'Authorisation details incorrect. ' \
                  'Please check the email and password supplied are correct, ' \
                  'or enable authentication with your email provider. ' \
                  'An application password may be required.'
        logger.write(time: Time.now, message: message)
        super(message)
      end
    end
  end
end
