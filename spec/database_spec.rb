# frozen_string_literal: true

require 'timecop'

require_relative '../lib/palantir'

describe Palantir::Database do
  before do
    allow(described_class).to receive(:query)
    stub_const('ENV', 'TEST' => 'true')
  end

  describe 'table_name' do
    context 'when TEST ENV variable is set' do
      it 'returns test database name' do
        expect(described_class.send(:table_name)).to eq('variables_test')
      end
    end

    context 'when TEST ENV variable is not set' do
      before do
        stub_const('ENV', 'TEST' => nil)
      end

      after do
        stub_const('ENV', 'TEST' => 'true')
      end

      it 'returns the database name' do
        expect(described_class.send(:table_name)).to eq('variables')
      end
    end
  end
end
