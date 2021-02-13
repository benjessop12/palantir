# frozen_string_literal: true

require 'date'

module Palantir
  class Analyzer
    class Reports
      MARKET_HOURS = 8

      attr_reader :ticker, \
                  :data_short,
                  :data_long,
                  :analysis,
                  :report_date

      attr_accessor :report_instance

      def initialize(ticker: nil, data_short: nil, data_long: nil, analysis: nil)
        @ticker = ticker
        @data_short = data_short
        @data_long = data_long
        @analysis = analysis
        @report_instance = ::Palantir::Models::Reports.new
        @report_date = Date.today.strftime('%Y-%m-%d')
      end

      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      def save!
        report_instance.save(
          data: {
            ticker: ticker,
            open: data_short.first,
            high: data_short.max,
            low: data_short.min,
            moving_average: analysis[:exponential_moving_average],
            relative_strength_index: analysis[:relative_strength_index][:rsi_step_two],
            buy_or_sell: analysis[:relative_strength_index][:sentiment],
            bottoms: count_of[:lows],
            tops: count_of[:highs],
            initial_hour_movement: hour_movement[:initial],
            power_hour_movement: hour_movement[:power_hour],
            date: report_date
          },
          environment: 'test',
        )
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

      def send_email(threads: nil)
        thread_count = threads.to_i
        reports = report_instance.report_by(date: report_date)
        return unless reports.flatten.count == thread_count

        ::Palantir::EmailUtility.send_email(
          body: report_body(reports: reports),
          subject: "Palantir Report: #{report_date}",
          recipient: recipient,
        )
      end

      private

      def hour_movement
        elements_per_assumed_hour = data_short.count % MARKET_HOURS # this needs revision
        {
          initial: movement(
            data: data_short.first(elements_per_assumed_hour),
          ),
          power_hour: movement(
            data: data_short.last(elements_per_assumed_hour),
          )
        }
      end

      def count_of
        {
          lows: data_short.count(data_short.min),
          highs: data_short.count(data_short.max)
        }
      end

      def movement(data: nil)
        initial = data.first
        closing = data.last
        return 0 if initial == closing

        closing - initial
      end

      def report_body(reports: nil)
        pp reports
      end

      def recipient
        file_contents = File.open(::Palantir::EMAIL_CONFIG_FILE).read.split
        file_contents.select { |e| e[/AuthUser/] }.first.gsub('AuthUser=', '')
      rescue Errno::ENOENT
        nil
      end
    end
  end
end
