# frozen_string_literal: true

module Palantir
  class Logger
    class Formatter
      FORMAT = "%s [%s]: %5s -- %s\n"
      LOG_LEVEL = 'WARN'

      class << self
        def call(time: nil, message: nil)
          format(FORMAT, LOG_LEVEL, as_time(time), Process.pid, as_message(message))
        end

        private

        def as_time(time)
          time.strftime('%Y-%m-%dT%H:%M:%S.%6N')
        end

        def as_message(message)
          case message
          when ::String
            message
          when ::Exception
            "#{message.message} (#{message.class})\n#{message.backtrace&.join("\n")}"
          else
            message.inspect
          end
        end
      end
    end
  end
end
