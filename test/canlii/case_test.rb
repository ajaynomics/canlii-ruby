# frozen_string_literal: true

require "test_helper"
require "minitest/mock"

module CanLII
  class CaseTest < CanLII::TestCase
    def setup
      super
      @original_language = CanLII.configuration.language
    end

    def teardown
      CanLII.configuration.language = @original_language
      Thread.current[:canlii_client] = nil
    end

    def test_find_returns_case_with_full_details
      case_detail = {
        "databaseId" => "csc-scc",
        "caseId" => "2025scc21",
        "title" => "Test Case v. Canada",
        "citation" => "2025 SCC 21",
        "url" => "https://canlii.ca/t/k1234",
        "decisionDate" => "2025-06-27",
        "language" => "en"
      }

      stub_request(:get, "https://api.canlii.org/v1/caseBrowse/en/csc-scc/2025scc21")
        .with(query: hash_including("api_key"))
        .to_return(status: 200, body: case_detail.to_json)

      kase = CanLII::Case.find("csc-scc", "2025scc21")

      refute_nil kase
      assert_equal "csc-scc", kase.database_id
      assert_equal "2025scc21", kase.case_id
      assert_equal "Test Case v. Canada", kase.title
      assert_equal "2025 SCC 21", kase.citation
      assert_equal "https://canlii.ca/t/k1234", kase.url
      assert_equal Date.parse("2025-06-27"), kase.decision_date
      assert_equal "en", kase.language
    end

    def test_find_returns_nil_for_404
      stub_request(:get, "https://api.canlii.org/v1/caseBrowse/en/csc-scc/invalid")
        .with(query: hash_including("api_key"))
        .to_return(status: 404, body: "Not found")

      result = CanLII::Case.find("csc-scc", "invalid")
      assert_nil result
    end

    def test_find_bang_raises_not_found_error_for_missing_case
      stub_request(:get, "https://api.canlii.org/v1/caseBrowse/en/csc-scc/invalid")
        .with(query: hash_including("api_key"))
        .to_return(status: 404, body: "Not found")

      error = assert_raises(CanLII::NotFoundError) do
        CanLII::Case.find!("csc-scc", "invalid")
      end

      assert_equal "Case not found: csc-scc/invalid", error.message
    end

    def test_find_uses_language_from_configuration
      CanLII.configuration.language = "fr"

      stub_request(:get, "https://api.canlii.org/v1/caseBrowse/fr/csc-scc/2025scc21")
        .with(query: hash_including("api_key"))
        .to_return(status: 200, body: '{"databaseId": "csc-scc", "caseId": "2025scc21"}')

      CanLII::Case.find("csc-scc", "2025scc21")

      assert_requested :get, "https://api.canlii.org/v1/caseBrowse/fr/csc-scc/2025scc21",
                       query: hash_including("api_key")
    end

    def test_to_s_returns_citation_when_available
      kase = CanLII::Case.new(
        database_id: "csc-scc",
        case_id: "2025scc21",
        title: "Test Case",
        citation: "2025 SCC 21"
      )

      assert_equal "2025 SCC 21", kase.to_s
    end

    def test_to_s_falls_back_to_title_when_no_citation
      kase = CanLII::Case.new(
        database_id: "csc-scc",
        case_id: "2025scc21",
        title: "Test Case"
      )

      assert_equal "Test Case", kase.to_s
    end

    def test_to_s_falls_back_to_database_id_slash_case_id_when_no_citation_or_title
      kase = CanLII::Case.new(
        database_id: "csc-scc",
        case_id: "2025scc21"
      )

      assert_equal "csc-scc/2025scc21", kase.to_s
    end

    def test_find_uses_default_client_when_called_without_with_client
      stub_request(:get, "https://api.canlii.org/v1/caseBrowse/en/csc-scc/test123")
        .with(query: hash_including("api_key"))
        .to_return(status: 200, body: '{"databaseId": "csc-scc", "caseId": "test123", "title": "Test"}')

      kase = CanLII::Case.find("csc-scc", "test123")

      refute_nil kase
      assert_equal "test123", kase.case_id
    end

    def test_with_client_overrides_default_client
      mock_client = Minitest::Mock.new
      response = {
        "databaseId" => "csc-scc",
        "caseId" => "mock123",
        "title" => "Mock Case"
      }
      mock_client.expect :get, response, ["/caseBrowse/en/csc-scc/mock123"]

      kase = CanLII::Case.with_client(mock_client) do
        CanLII::Case.find("csc-scc", "mock123")
      end

      assert_equal "mock123", kase.case_id
      assert_equal "Mock Case", kase.title
      mock_client.verify
    end

    def test_with_client_restores_previous_client_after_block
      initial_client = CanLII::Client.new
      Thread.current[:canlii_client] = initial_client

      mock_client = Minitest::Mock.new
      mock_client.expect :get, { "databaseId" => "test", "caseId" => "123" }, ["/caseBrowse/en/test/123"]

      CanLII::Case.with_client(mock_client) do
        CanLII::Case.find("test", "123")
      end

      assert_same initial_client, Thread.current[:canlii_client]
      mock_client.verify
    end

    def test_browse_returns_array_of_cases
      browse_response = {
        "cases" => [
          {
            "databaseId" => "csc-scc",
            "caseId" => { "en" => "2025scc21" },
            "title" => "Test Case v. Canada",
            "citation" => "2025 SCC 21"
          },
          {
            "databaseId" => "csc-scc",
            "caseId" => "2025scc20",
            "title" => "Another Case",
            "citation" => "2025 SCC 20",
            "decisionDate" => "2025-06-20"
          }
        ]
      }

      stub_request(:get, "https://api.canlii.org/v1/caseBrowse/en/csc-scc")
        .with(query: hash_including("api_key", "offset" => "0", "resultCount" => "20"))
        .to_return(status: 200, body: browse_response.to_json)

      cases = CanLII::Case.browse("csc-scc")

      assert_equal 2, cases.length
      assert_instance_of CanLII::Case, cases.first
      assert_equal "2025scc21", cases.first.case_id
      assert_equal "Test Case v. Canada", cases.first.title
      assert_equal "2025 SCC 21", cases.first.citation
      assert_equal Date.parse("2025-06-20"), cases[1].decision_date
    end

    def test_browse_handles_empty_response
      stub_request(:get, "https://api.canlii.org/v1/caseBrowse/en/csc-scc")
        .with(query: hash_including("api_key"))
        .to_return(status: 200, body: '{"cases": []}')

      cases = CanLII::Case.browse("csc-scc")
      assert_equal [], cases
    end

    def test_browse_handles_error_array_response
      stub_request(:get, "https://api.canlii.org/v1/caseBrowse/en/invalid")
        .with(query: hash_including("api_key"))
        .to_return(status: 200, body: "[]")

      cases = CanLII::Case.browse("invalid")
      assert_equal [], cases
    end

    def test_browse_accepts_pagination_options
      stub_request(:get, "https://api.canlii.org/v1/caseBrowse/en/csc-scc")
        .with(query: { "api_key" => "test_key", "language" => "en", "offset" => "50", "resultCount" => "100" })
        .to_return(status: 200, body: '{"cases": []}')

      CanLII::Case.browse("csc-scc", offset: 50, limit: 100)

      assert_requested :get, "https://api.canlii.org/v1/caseBrowse/en/csc-scc",
                       query: { "api_key" => "test_key", "language" => "en", "offset" => "50", "resultCount" => "100" }
    end

    def test_browse_accepts_date_filters
      after_date = Date.parse("2025-01-01")
      before_date = Date.parse("2025-12-31")

      stub_request(:get, "https://api.canlii.org/v1/caseBrowse/en/csc-scc")
        .with(query: hash_including(
          "decisionDateAfter" => "2025-01-01",
          "decisionDateBefore" => "2025-12-31"
        ))
        .to_return(status: 200, body: '{"cases": []}')

      CanLII::Case.browse("csc-scc", published_after: after_date, published_before: before_date)

      assert_requested :get, "https://api.canlii.org/v1/caseBrowse/en/csc-scc",
                       query: hash_including(
                         "decisionDateAfter" => "2025-01-01",
                         "decisionDateBefore" => "2025-12-31"
                       )
    end

    def test_browse_with_custom_client
      mock_client = Minitest::Mock.new
      response = { "cases" => [] }
      mock_client.expect :get, response, ["/caseBrowse/en/test-db", { offset: 0, resultCount: 20 }]

      cases = CanLII::Case.with_client(mock_client) { CanLII::Case.browse("test-db") }

      assert_equal [], cases
      mock_client.verify
    end
  end
end
