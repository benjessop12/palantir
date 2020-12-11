# frozen_string_literal: true

require 'json'

module Palantir
  module Extractors
    class Reddit
      class ThreadData
        attr_reader :subreddit, \
                    :thread, \
                    :meta_data, \
                    :data

        URL_FORMAT = 'https://www.reddit.com/r/%s/.json'

        def initialize(subreddit: nil, thread: nil)
          @subreddit = subreddit
          @thread = thread
          @meta_data, @data = latest_thread_data
        end

        def comments
          ::Enumerator.new do |yielder|
            data['data']['children'].each { |el| yielder.yield el['data']['body'] }
          end
        end

        private

        def latest_thread_data
          initial_endpoint = format(URL_FORMAT, subreddit)
          pinned_id = get_pinned_id(scrape_json(initial_endpoint))
          thread_endpoint_json = format(URL_FORMAT, "#{subreddit}/comments/#{pinned_id}")
          scrape_json(thread_endpoint_json)
        end

        def scrape_json(request_url)
          response = Palantir::Clients::BaseClient.get(request_url)
          ::JSON.parse response.http_body.content
        end

        def get_pinned_id(json)
          json['data']['children'][thread.to_i]['data']['id']
        end
      end
    end
  end
end
