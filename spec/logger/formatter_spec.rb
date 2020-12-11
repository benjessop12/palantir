# frozen_string_literal: true

require 'date'
require_relative '../../lib/palantir'

describe Palantir::Logger::Formatter do
  let(:time) { DateTime.parse('2020-12-01 00:00:00') }

  context 'when given valid params and message as string' do
    let(:message) { 'This is a log message' }

    before do
      allow(Process).to receive(:pid).and_return(100)
    end

    it 'yields the message in valid log format' do
      expect(described_class.call(time: time, message: message)).to eq(
        "WARN [2020-12-01T00:00:00.000000]:   100 -- This is a log message\n",
      )
    end
  end
end
