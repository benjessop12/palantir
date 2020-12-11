# frozen_string_literal: true

require 'timecop'
require 'webmock'

require_relative '../../lib/palantir'

describe Palantir::Utility::HttpClientWrapper do
  include WebMock::API
  WebMock.enable!
  let(:logger) { Palantir::Logger.new(file_path: 'tmp.txt') }
  let(:client_wrapper) { described_class.new(logger: logger) }

  before do
    allow(logger).to receive(:write)
    Timecop.freeze(Time.local(2020))
  end

  after do
    Timecop.return
  end

  describe 'get' do
    context 'when a basic URL is requested' do
      before do
        stub_request(:get, 'http://example.com').to_return(body: 'sample_text')
      end

      it 'gets the content' do
        expect(client_wrapper.get('http://example.com').body).to eq 'sample_text'
      end

      it 'writes the response to the log' do
        client_wrapper.get('http://example.com')
        expect(logger).to have_received(:write).with(
          {
            message: 'sample_text',
            time: Time.new(2020)
          },
        )
      end
    end

    context 'when an exception occurs' do
      let(:bad_response) { HTTPClient::BadResponseError.new('Exception from WebMock') }
      before do
        stub_request(:get, 'http://example.com')
          .to_raise bad_response
      end

      context 'and the client has a logger' do
        let(:client_wrapper_with_logger) { described_class.new(logger: logger) }

        it 'writes the exception to the log' do
          client_wrapper_with_logger.get('http://example.com')
          expect(logger).to have_received(:write).with(
            {
              message: bad_response,
              time: Time.new(2020)
            },
          )
        end
      end
    end
  end

  describe 'post' do
    context 'when a basic POST request is requested' do
      before do
        stub_request(:post, 'http://example.com')
          .with(body: { 'POSTED_DATA' => nil })
          .to_return(status: 200, body: 'RESPONSE')
      end

      it 'posts string content to the specified url and receives response data' do
        expect(
          client_wrapper.post('http://example.com', data: 'POSTED_DATA').body,
        ).to eq('RESPONSE')
      end
    end

    context 'when auth credentials are passed' do
      let(:api_key) { '123' }

      before do
        stub_request(:post, "http://example#{api_key}@example.com")
          .with(body: { 'POSTED_DATA' => nil })
          .to_return(status: 200, body: 'RESPONSE')
      end

      it 'posts data with api key in request and gets back response data' do
        expect(
          client_wrapper.post('http://example.com', data: 'POSTED_DATA', auth_password: api_key,
                                                    auth_user_name: 'palantir').body,
        ).to eq('RESPONSE')
      end
    end
  end
end
