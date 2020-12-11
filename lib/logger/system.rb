# frozen_string_literal: true

module Palantir
  class Logger
    class System
      class << self
        def prog_user
          return `whoami` if mac? || linux?
          return ENV['USERNAME'] if windows?
        end

        def windows?
          (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ ::RUBY_PLATFORM) != nil
        end

        def mac?
          (/darwin/ =~ ::RUBY_PLATFORM) != nil
        end

        def linux?
          unix? and !mac?
        end

        def unix?
          !windows?
        end
      end
    end
  end
end
