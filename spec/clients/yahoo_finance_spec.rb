# frozen_string_literal: true

require 'webmock'

require_relative '../../lib/palantir'

class MockResponse
  class << self
    def body
      '"CrumbStore":{"crumb":"TestCrumb'
    end

    def http_header
      MockInstanceSetter
    end
  end

  class MockInstanceSetter
    @header_item = [['Set-Cookie', 'Mock; Something']]
  end
end

class MockInfo
  class << self
    def body
      %(Date,Open,High,Low,Close,Adj Close,Volume
2021-01-04,23.910000,24.500000,22.500000,23.370001,23.370001,44970400
2021-01-05,23.180000,24.670000,22.889999,24.600000,24.600000,29050400
2021-01-06,24.120001,24.459999,23.250000,23.540001,23.540001,32732900
2021-01-07,24.020000,25.190001,23.670000,25.000000,25.000000,32240000
2021-01-08,25.700001,26.440001,24.700001,25.200001,25.200001,41313800)
    end
  end
end

describe Palantir::Clients::YahooFinance do
  include WebMock::API
  WebMock.enable!

  let(:described_instance) do
    described_class.new(
      stock_code: 'PLTR',
      start_date: '2021-01-01',
      end_date: '2021-01-10',
    )
  end
  let(:request_url) { Palantir::Clients::YahooFinance::BASE_URL }

  before do
    stub_request(:get, request_url)
    described_instance.instance_variable_set(:@page_data, MockResponse)
  end

  describe 'collect_data' do
    let(:unstructured_data) do
      [
        ['Date', 'Open', 'High', 'Low', 'Close', 'Adj Close', 'Volume'],
        ['2020-01-02', 84.900002, 86.139999, 84.342003, 86.052002, 86.052002, 47_660_500],
        ['2020-01-03', 88.099998, 90.800003, 87.384003, 88.601997, 88.601997, 88_892_500]
      ]
    end

    before do
      allow(described_instance).to receive(:fetch_data).and_return(unstructured_data)
    end

    it 'converts the csv data to a hash' do
      expect(described_instance.collect_data).to eq(
        [
          {
            'Date' => '2020-01-02',
            'Open' => 84.900002,
            'High' => 86.139999,
            'Low' => 84.342003,
            'Close' => 86.052002,
            'Adj Close' => 86.052002,
            'Volume' => 47_660_500
          },
          {
            'Date' => '2020-01-03',
            'Open' => 88.099998,
            'High' => 90.800003,
            'Low' => 87.384003,
            'Close' => 88.601997,
            'Adj Close' => 88.601997,
            'Volume' => 88_892_500
          }
        ],
      )
    end
  end

  describe 'fetch_data' do
    let(:expected_output) do
      [
        ['Date', 'Open', 'High', 'Low', 'Close', 'Adj Close', 'Volume'],
        ['2021-01-04', 23.91, 24.5, 22.5, 23.370001, 23.370001, 44_970_400],
        ['2021-01-05', 23.18, 24.67, 22.889999, 24.6, 24.6, 29_050_400],
        ['2021-01-06', 24.120001, 24.459999, 23.25, 23.540001, 23.540001, 32_732_900],
        ['2021-01-07', 24.02, 25.190001, 23.67, 25.0, 25.0, 32_240_000],
        ['2021-01-08', 25.700001, 26.440001, 24.700001, 25.200001, 25.200001, 41_313_800]
      ]
    end

    before do
      allow(described_instance).to receive(:get).and_return(MockInfo)
    end

    it 'returns ticker data for the specified time period' do
      expect(described_instance.send(:fetch_data)).to eq(expected_output)
    end
  end

  describe 'as_date' do
    it 'converts to unix time' do
      expect(described_instance.send(:as_date, date: '2021-01-01')).to eq(1_609_459_200)
    end
  end

  describe 'build_url' do
    let(:expected_output) do
      'https://query1.finance.yahoo.com/v7/finance/download/PLTR?events=history&interval=1d' \
      '&period1=1609459200&period2=1610236800&crumb=TestCrumb'
    end

    it 'returns valid ticker url' do
      expect(described_instance.send(:build_url)).to eq(expected_output)
    end
  end

  describe 'fetch_crumb' do
    it 'extracts the crumb' do
      expect(described_instance.send(:fetch_crumb)).to eq('TestCrumb')
    end
  end
end
