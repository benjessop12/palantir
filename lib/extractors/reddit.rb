# frozen_string_literal: true

require 'time'

Dir.glob('./lib/extractors/reddit/*.rb').sort.each { |file| require file }

module Palantir
  module Extractors
    class Reddit
      include Base::Regex

      attr_reader :subreddit, \
                  :results

      RISK_AND_SUBREDDIT = {
        HIGH: 'wallstreetbets',
        LOW: 'investing'
      }.freeze

      def initialize(risk_level: nil)
        @subreddit = if risk_level == 'HIGH'
                       RISK_AND_SUBREDDIT[:HIGH]
                     else
                       RISK_AND_SUBREDDIT[:LOW]
                     end
        @results = Hash.new { |k, v| k[v] = [] }
      end

      def extract_data
        Reddit::ThreadData.new(subreddit: subreddit).comments.each do |comment|
          detect_data_from_string(string: comment)
        end
      end

      def best_option(defined_tickers: [])
        weighed_options = {}
        new_tickers(defined_tickers: defined_tickers).each do |ticker|
          current_price = ::Palantir::Clients::GoogleClient.get_ticker(ticker)[:value].to_f
          weighed_options[ticker] = strength_of_shill(current_price: current_price, data: results[ticker.to_sym])
        end
        weighed_options.key(weighed_options.values.max)
      end

      private

      def detect_data_from_string(string: nil)
        code = code_from(string: string)
        return if code.nil? || code.length.zero?

        currency = currency_from(string: string)
        date = date_from(string: string)
        @results[code.to_sym] << { date: date, currency: currency }
      end

      def new_tickers(defined_tickers: nil)
        results.keys.map(&:to_s).reject { |el| defined_tickers.include? el }
      end

      def strength_of_shill(current_price: nil, data: nil)
        strength = []
        data.each do |data_hash|
          shill_data = collect_data_for_shill(data_hash: data_hash, current_price: current_price)
          strength << shill_data if shill_data
        end
        strength.sum + data.count
      end

      def collect_data_for_shill(data_hash: {}, current_price: nil)
        return if data_hash[:date].nil? || data_hash[:date].empty?

        unix_length = Time.parse(data_hash[:date]) - Time.now
        return if unix_length.negative?

        base_percentage_increase = (data_hash[:currency].to_f / current_price) * 100
        strength_of_individual_shill(unix_length: unix_length,
                                     base_percentage_increase: base_percentage_increase)
      rescue ::ArgumentError
        nil
      end

      def strength_of_individual_shill(unix_length: nil, base_percentage_increase: nil)
        (base_percentage_increase / unix_length.to_i.digits.count).to_i
      end
    end
  end
end
