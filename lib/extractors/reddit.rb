# frozen_string_literal: true

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

      private

      def detect_data_from_string(string: nil)
        code = code_from(string: string)
        return if code.nil? || code.length.zero?

        currency = currency_from(string: string)
        date = date_from(string: string)
        @results[code.to_sym] << { date: date, currency: currency }
      end
    end
  end
end
