# frozen_string_literal: true

module Palantir
  module Extractors
    module Base
      class Sanitizer
        class << self
          FALSE_WORDS = %w[
            WSB
            OK
            EOH
            EOD
            EOW
            EOQ
            EOY
            USA
            FUCK
            WOW
            SHIT
          ].freeze
          FALSE_REGEX = /\b(?:#{FALSE_WORDS.join('|')})\b/i.freeze

          def remove_falsities(string: nil)
            string.gsub(FALSE_REGEX, '')
          end
        end
      end
    end
  end
end
