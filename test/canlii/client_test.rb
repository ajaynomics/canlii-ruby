# frozen_string_literal: true

require "test_helper"

module CanLII
  class ClientTest < CanLII::TestCase
    def setup
      super
      @client = CanLII::Client.new
    end

    def test_get_includes_api_key_in_request_params
      stub_request(:get, "https://api.canlii.org/v1/test")
        .with(query: hash_including("api_key" => "test_key", "language" => "en"))
        .to_return(status: 200, body: '{"success": true}', headers: { "Content-Type" => "application/json" })

      @client.get("/test")

      assert_requested :get, "https://api.canlii.org/v1/test",
                       query: hash_including("api_key" => "test_key")
    end

    def test_get_returns_parsed_json_for_successful_response
      expected_response = { "cases" => [{ "id" => "123", "title" => "Test Case" }] }

      stub_request(:get, "https://api.canlii.org/v1/caseBrowse/en")
        .with(query: hash_including("api_key"))
        .to_return(
          status: 200,
          body: expected_response.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = @client.get("/caseBrowse/en")

      assert_equal expected_response, result
      assert_equal "123", result["cases"][0]["id"]
    end

    def test_get_merges_additional_params_with_api_key
      stub_request(:get, "https://api.canlii.org/v1/caseBrowse/en/csc-scc")
        .with(query: { "api_key" => "test_key", "language" => "en", "offset" => "0", "resultCount" => "10" })
        .to_return(status: 200, body: '{"cases": []}')

      @client.get("/caseBrowse/en/csc-scc", offset: 0, resultCount: 10)

      assert_requested :get, "https://api.canlii.org/v1/caseBrowse/en/csc-scc",
                       query: { "api_key" => "test_key", "language" => "en", "offset" => "0", "resultCount" => "10" }
    end

    def test_get_raises_response_error_for_non_200_status
      stub_request(:get, "https://api.canlii.org/v1/test")
        .with(query: hash_including("api_key"))
        .to_return(status: 404, body: "Not found")

      error = assert_raises(CanLII::NotFoundError) do
        @client.get("/test")
      end

      assert_equal "Resource not found", error.message
    end

    def test_handles_various_http_error_codes
      error_mapping = {
        401 => CanLII::AuthenticationError,
        403 => CanLII::AuthenticationError,
        429 => CanLII::RateLimitError,
        500 => CanLII::ResponseError,
        503 => CanLII::ResponseError
      }

      error_mapping.each do |status, error_class|
        stub_request(:get, "https://api.canlii.org/v1/error#{status}")
          .with(query: hash_including("api_key"))
          .to_return(status: status, body: "Error #{status}")

        assert_raises(error_class) do
          @client.get("/error#{status}")
        end
      end
    end

    def test_get_uses_configuration_values
      assert_equal "test_key", CanLII.configuration.api_key
      assert_equal "https://api.canlii.org/v1", CanLII.configuration.base_url

      stub_request(:get, "https://api.canlii.org/v1/test")
        .with(query: { "api_key" => "test_key", "language" => "en" })
        .to_return(status: 200, body: "{}")

      @client.get("/test")

      assert_requested :get, "https://api.canlii.org/v1/test",
                       query: { "api_key" => "test_key", "language" => "en" }
    end
  end
end
