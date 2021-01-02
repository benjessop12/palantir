# frozen_string_literal: true

require_relative '../../lib/palantir'

describe Palantir::Database::ShareLock do
  let(:dummy_class) { described_class.new }

  describe 'permit_concurrent_loads' do
    context 'when given a block' do
      before do
        allow(dummy_class).to receive(:wait_for)
      end

      it 'will wait before calling' do
        dummy_class.permit_concurrent_loads { p 'hi' }
        expect(dummy_class).to have_received(:wait_for)
      end
    end
  end
end
