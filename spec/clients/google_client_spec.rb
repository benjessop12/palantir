# frozen_string_literal: true

require 'webmock'

require_relative '../../lib/palantir'

describe Palantir::Clients::GoogleClient do
  include WebMock::API
  WebMock.enable!

  describe 'the general API' do
    let(:request_url) { 'https://www.google.com/api/PLTR' }

    before do
      stub_request(:get,
                   request_url)
        .to_return(body: '<div class=\"BNeawe iBp4i AP7Wnd\">26.12 <span class=\"rQMQod lB8g7\">')
      stub_const('Palantir::Clients::GoogleClient::BASE_FORMAT', request_url)
    end

    it 'extracts ticker from html response' do
      expect(described_class.get_ticker('PLTR')[:value]).to eq(26.12)
    end
  end
end
