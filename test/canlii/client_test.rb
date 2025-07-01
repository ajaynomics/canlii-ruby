# frozen_string_literal: true

require "test_helper"

module CanLII
  class ClientTest < CanLII::TestCase
    def setup
      super
      @client = CanLII::Client.new
    end

    def test_get_includes_required_params
      stub_api_request("/test", { success: true })

      @client.get("/test")

      assert_requested :get, "https://api.canlii.org/v1/test",
                       query: hash_including("api_key" => "test_key", "language" => "en")
    end

    def test_get_returns_parsed_json
      response = { "cases" => [{ "id" => "123", "title" => "Test Case" }] }
      stub_api_request("/caseBrowse/en", response)

      result = @client.get("/caseBrowse/en")

      assert_equal response, result
    end

    def test_get_merges_custom_params
      stub_api_request("/search", {}, query: { "q" => "test", "limit" => "10" })

      @client.get("/search", q: "test", limit: 10)

      assert_requested :get, "https://api.canlii.org/v1/search",
                       query: hash_including("q" => "test", "limit" => "10")
    end

    def test_error_handling_by_status_code
      {
        401 => [AuthenticationError, "Invalid API key"],
        403 => [AuthenticationError, "Invalid API key"],
        404 => [NotFoundError, "Resource not found"],
        429 => [RateLimitError, "Rate limit exceeded"],
        500 => [ResponseError, /HTTP 500/],
        503 => [ResponseError, /HTTP 503/]
      }.each do |status, (error_class, message)|
        stub_api_request("/error#{status}", "Error body", status: status)

        assert_error_raised(error_class, message) do
          @client.get("/error#{status}")
        end
      end
    end

    def test_handles_non_json_response
      stub_request(:get, "https://api.canlii.org/v1/broken")
        .with(query: hash_including("api_key"))
        .to_return(status: 200, body: "<html>Not JSON</html>")

      assert_error_raised(ResponseError, /Invalid JSON response/) do
        @client.get("/broken")
      end
    end
  end
end
