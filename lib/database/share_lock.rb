# frozen_string_literal: true

module Palantir
  module Database
    class ShareLock
      include MonitorMixin

      attr_reader :sleeping

      attr_accessor :exclusive_thread, \
                    :cv

      def initialize
        @cv = new_cond
        @sleeping = {}
        @exclusive_thread = nil
      end

      def permit_concurrent_loads(&block)
        start_exclusive
        begin
          block.call
        ensure
          synchronize do
            wait_for(method: :permit_concurrent_loads) { exclusive_thread && exclusive_thread != Thread.current }
          end
        end
      end

      private

      def start_exclusive
        synchronize do
          @exclusive_thread = Thread.current
        end
      end

      def wait_for(method: nil, &block)
        sleeping[Thread.current] = method
        cv.wait_while(&block)
      ensure
        sleeping.delete Thread.current
      end
    end
  end
end
