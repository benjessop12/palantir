# frozen_string_literal: true

require 'json'
require 'webmock'

require_relative '../../../lib/palantir'

describe Palantir::Extractors::Reddit::ThreadData do
  include WebMock::API
  WebMock.enable!

  context 'general API' do
    let(:sample_data_for_id) do
      {
        'data' => {
          'children' => [
            {
              'data' => {
                'id' => 'FAKEID'
              }
            }
          ]
        }
      }.to_json
    end
    let(:sample_thread_data) do
      [{
        'metadata' => []
      },
       {
         'data' => {
           'children' => [
             {
               'data' => {
                 'body' => 'TESTCOMMENT'
               }
             }
           ]
         }
       }].to_json
    end
    let(:subreddit) { 'wallstreetbets' }

    before do
      stub_request(:get, 'https://www.reddit.com/r/wallstreetbets/.json')
        .to_return(body: sample_data_for_id)
      stub_request(:get, 'https://www.reddit.com/r/wallstreetbets/comments/FAKEID/.json')
        .to_return(body: sample_thread_data)
    end

    it 'yields comments from expected response' do
      expect(described_class.new(subreddit: 'wallstreetbets').comments.first).to eq('TESTCOMMENT')
    end
  end
end
