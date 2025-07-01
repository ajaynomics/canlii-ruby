# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "minitest/autorun"
require "webmock/minitest"
require "canlii"

module CanLII
  class TestCase < Minitest::Test
    def setup
      CanLII.configuration.api_key = "test_key"
    end

    def teardown
      Thread.current[:canlii_client] = nil
      WebMock.reset!
    end

    private

    # Helper to stub API requests with common patterns
    def stub_api_request(path, response_body, status: 200, query: {})
      base_query = { "api_key" => "test_key", "language" => "en" }.merge(query)

      stub_request(:get, "#{CanLII.configuration.base_url}#{path}")
        .with(query: hash_including(base_query))
        .to_return(
          status: status,
          body: response_body.is_a?(String) ? response_body : response_body.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    # Helper to create a mock client with expectations
    def create_mock_client
      mock = Minitest::Mock.new
      yield mock if block_given?
      mock
    end

    # Helper to assert error is raised with correct message
    def assert_error_raised(error_class, message_pattern = nil, &block)
      error = assert_raises(error_class, &block)

      if message_pattern
        if message_pattern.is_a?(Regexp)
          assert_match message_pattern, error.message
        else
          assert_equal message_pattern, error.message
        end
      end

      error
    end
  end
end
