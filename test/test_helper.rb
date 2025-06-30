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
  end
end
