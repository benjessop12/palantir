# frozen_string_literal: true

module Palantir
  module Clients
    module GoogleClient
      extend BaseClient
      extend self

      BASE_FORMAT = 'https://www.google.com/search?source=hp&' \
                 'q=%s+stock&oq=%s+stock'

      def get_ticker(stock_code)
        url = format(BASE_FORMAT, stock_code, stock_code)
        {
          request_time: Time.now,
          value: parse_response(get(url))
        }
      end

      private

      def parse_response(response)
        response.http_body.content.match(/.">[0-9]{1,3}\.[0-9]{2} </)
                .to_s.match(/\d{1,3}\.\d{2}/)
                .to_s
                .to_f
      end
    end
  end
end
