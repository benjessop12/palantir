# frozen_string_literal: true

Dir.glob('./lib/analyzer/indicators/*.rb').sort.each { |file| require file }

module Palantir
  class Analyzer
    class Indicators
      def stub_class?
        # stub method
        true
      end
    end
  end
end
