# frozen_string_literal: true

require 'timecop'

require_relative '../lib/palantir'

describe Palantir::Database do
  before do
    allow(described_class).to receive(:query)
  end

  describe 'save_var' do
    before do
      Timecop.freeze(Time.local(2020))
    end

    after do
      Timecop.return
    end

    context 'when date is passed' do
      it 'sends valid sql for querying' do
        described_class.save_var(name: 'PLTR', value: 'test', at_date: Time.parse('2020-02-01'))
        expect(described_class).to have_received(:query)
          .with(sql: "INSERT INTO variables(name, value, at_date) VALUES ('PLTR', 'test', '2020-02-01')")
      end
    end

    context 'when date is not passed' do
      it 'sends valid sql for querying' do
        described_class.save_var(name: 'PLTR', value: 'test')
        expect(described_class).to have_received(:query)
          .with(sql: "INSERT INTO variables(name, value, at_date) VALUES ('PLTR', 'test', '2020-01-01')")
      end
    end
  end

  describe 'get_var' do
    it 'sends valid sql for querying' do
      described_class.get_var(name: 'PLTR')
      expect(described_class).to have_received(:query)
        .with(sql: "SELECT value, at_date FROM variables WHERE name == 'PLTR'", values: true)
    end
  end
end
