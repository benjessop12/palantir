# frozen_string_literal: true

module Palantir
  module Clients
    # base client
    module BaseClient
      extend self

      CONNECT_TIMEOUT = 60 * 60
      RECEIVE_TIMEOUT = 60 * 60

      def get(url, query: nil, auth_password: nil, auth_user_name: nil)
        base_http_client.get(url, query: query, auth_password: auth_password, auth_user_name: auth_user_name)
      end

      private

      def base_http_client
        @base_http_client ||= ::Palantir::Utility::HttpClientWrapper.new(
          logger: ::Palantir::Logger.new(file_path: ::Palantir::LOG_FILE_PATH),
          connect_timeout: CONNECT_TIMEOUT,
          receive_timeout: RECEIVE_TIMEOUT,
        )
      end
    end
  end
end
