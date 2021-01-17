# frozen_string_literal: true

require 'csv'

module Palantir
  module Clients
    class YahooFinance
      include BaseClient

      BASE_URL = 'https://finance.yahoo.com/quote/AAPL/history?p=AAPL'
      CRUMB_PATTERN = /"CrumbStore":{"crumb":"(?<crumb>[^"]+)/.freeze
      EVENT_TYPE = 'history'
      INTERVAL = '1d'
      QUOTE_ENDPOINT = 'https://query1.finance.yahoo.com/v7/finance/download/%{symbol}?' # rubocop:disable Style/FormatStringToken
      TRIES = 5

      attr_reader :page_data, \
                  :params, \
                  :stock_code, \
                  :connection

      def initialize(stock_code: nil, start_date: nil, end_date: nil)
        @page_data = request_page
        @params = {
          events: EVENT_TYPE,
          interval: INTERVAL,
          period1: as_date(date: start_date),
          period2: as_date(date: end_date)
        }
        @stock_code = stock_code
      end

      def collect_data
        unstructured_data = fetch_data
        keys = unstructured_data.shift
        unstructured_data.map { |a| Hash[keys.zip(a)] }
      end

      private

      def fetch_data
        TRIES.times do |_x|
          @connection = get build_url
          break
        rescue OpenURI::HTTPError
          request_page
        end

        ::CSV.parse(connection.body, converters: :numeric)
      end

      def as_date(date: nil)
        DateTime.parse(date).to_time.to_i
      end

      def build_url
        url = format(QUOTE_ENDPOINT, symbol: stock_code.upcase)
        url + params.merge(crumb: fetch_crumb).merge(Cookie: fetch_cookie).map { |k, v| "#{k}=#{v}" }.join('&').to_s
      end

      def fetch_cookie
        page_data.http_header.instance_variable_get(:@header_item)
                 .select { |a| a.first == 'Set-Cookie' }
                 .first
                 .last
                 .split('; ', 2)
                 .first
      end

      def fetch_crumb
        page_data.body.match(CRUMB_PATTERN)['crumb']
      end

      def request_page
        get BASE_URL
      end
    end
  end
end
