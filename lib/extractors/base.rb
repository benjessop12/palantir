# frozen_string_literal: true

Dir.glob('./lib/extractors/base/*.rb').sort.each { |file| require file }

module Palantir
  module Extractors
    module Base
    end
  end
end
