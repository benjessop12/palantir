# frozen_string_literal: true

require 'httpclient'

module Palantir
  module Utility
    class HttpClientWrapper
      attr_accessor :client, \
                    :logger

      def initialize(logger: nil, connect_timeout: nil, receive_timeout: nil)
        @client = HTTPClient.new(agent_name: 'palantir', connect_timeout: connect_timeout,
                                 receive_timeout: receive_timeout)
        @logger = logger
        @requests = []
      end

      def get(url, query: nil, auth_password: nil, auth_user_name: nil)
        process_request_response(url, _query: query, auth_password: auth_password, auth_user_name: auth_user_name) do
          client.get(url, query)
        end
      end

      def post(url, data: nil, auth_password: nil, auth_user_name: nil)
        process_request_response(url, auth_password: auth_password, auth_user_name: auth_user_name) do
          client.post(url, data)
        end
      end

      def collect_requests(latest_status_code)
        @requests.shift if @requests.size == 10
        @requests << latest_status_code.to_s
      end

      private

      # rubocop:disable Metrics/MethodLength
      def process_request_response(url, _query: nil, auth_password: nil, auth_user_name: nil)
        check_auth(request_url: url, auth_user_name: auth_user_name, auth_password: auth_password)
        request_time = Time.now.utc
        response = yield
        collect_requests(response.status)

        if (400..499).include? response.status
          raise Palantir::Exceptions::NotFound.new(end_point: url, status_code: response.status,
                                                   logger: @logger)
        end
        logger.write(time: request_time, message: response.body)
        response
      rescue Timeout::Error, SystemCallError, SocketError, EOFError, HTTPClient::BadResponseError,
             HTTPClient::TimeoutError => e
        logger.write(time: request_time, message: e)
      end
      # rubocop:enable Metrics/MethodLength

      def check_auth(request_url: url, auth_user_name: nil, auth_password: nil)
        return unless auth_user_name && auth_password

        client.force_basic_auth = true
        client.set_auth(request_url, auth_user_name, auth_password)
      end
    end
  end
end
