# frozen_string_literal: true

require 'open3'

module Palantir
  module EmailUtility
    module_function

    def send_email(body = nil, subject = nil, recipient = nil)
      email_command = "echo '#{body}'' | mail -s '#{subject}'' #{recipient}"
      result_code(Open3.capture3(email_command))
    end

    def result_code(output)
      server_response = output[1]
      raise ::Palantir::Exceptions::AuthorisationIssue.new(logger: ::Palantir.logger) \
        if server_response[/535 5.7.8/]

      'Email sent.'
    end
  end
end
