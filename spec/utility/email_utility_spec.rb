# frozen_string_literal: true

require_relative '../../lib/palantir'

class StubLogger
  class << self
    def write(time: nil, message: nil)
    end
  end
end

describe Palantir::EmailUtility do
  describe 'result_code' do
    context 'when the email failed to send' do
      let(:output) do
        [
          '',
          'send-mail: Authorization failed (535 5.7.8  ' \
          'https://support.google.com/mail/?p=BadCredentials t1sm2091707pfl.194 - gsmtp)\n'
        ]
      end

      it 'raises authorisation error' do
        expect { described_class.result_code(output) }.to raise_error(::Palantir::Exceptions::AuthorisationIssue)
      end
    end

    context 'when the email successfully sent' do
      let(:output) { 'success' }

      it 'returns Email sent. text' do
        expect(described_class.result_code(output)).to eq('Email sent.')
      end
    end
  end
end
