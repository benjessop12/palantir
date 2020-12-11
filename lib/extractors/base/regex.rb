# frozen_string_literal: true

module Palantir
  module Extractors
    module Base
      module Regex
        module_function

        DATE_SEPERATORS = ['/', '-'].freeze
        MAX_MONTH = 12

        def code_from(string: nil)
          return if string.nil? || string.length.zero?

          string.match(/[(^| )][^?!#]?[A-Z]{3,4}[( |$)]/).to_s.strip
        end

        def currency_from(string: nil)
          return if string.length.zero?

          string.match(/[(£|$)]?[0-9]{1,3}[(,|.)]?[0-9]?{1,3}[^!%]?( |$)/).to_s.strip
        end

        def date_from(string: nil)
          return if string.length.zero?

          date_match = string.match(%r{[(^| )]\d{1,2}(-|/)\d{1,2}}).to_s.strip
          convert_date(date: date_match)
        end

        def convert_date(date: nil)
          return '' if date.length.zero?

          date_array = date.split(/#{DATE_SEPERATORS}/)
          return date_array.join('-') unless assert_parsing(date_array: date_array)

          date_array.sort.reverse.join('-')
        end

        def assert_parsing(date_array: nil)
          max_element = date_array.max_by { |x| x[/\d+/].to_i }
          max_element.to_i > MAX_MONTH
        end
      end
    end
  end
end
