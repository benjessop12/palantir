# frozen_string_literal: true

require_relative '../../lib/palantir'

describe Palantir::Logger::System do
  context 'on Mac OS' do
    before do
      stub_const('::RUBY_PLATFORM', 'x86_64-darwin18')
    end

    describe 'windows?' do
      it 'returns false' do
        expect(described_class.windows?).to eq(false)
      end
    end

    describe 'mac?' do
      it 'returns true' do
        expect(described_class.mac?).to eq(true)
      end
    end
  end

  context 'on Windows OS' do
    before do
      stub_const('::RUBY_PLATFORM', 'mingw')
    end

    describe 'windows?' do
      it 'returns true' do
        expect(described_class.windows?).to eq(true)
      end
    end

    describe 'mac?' do
      it 'returns false' do
        expect(described_class.mac?).to eq(false)
      end
    end
  end
end
