# frozen_string_literal: true

require "test_helper"
require "minitest/mock"

module CanLII
  class DatabaseTest < CanLII::TestCase
    def setup
      super
      @original_language = CanLII.configuration.language
    end

    def teardown
      CanLII.configuration.language = @original_language
      Thread.current[:canlii_client] = nil
    end

    def test_all_returns_array_of_database_objects
      mock_client = Minitest::Mock.new
      mock_response = {
        "caseDatabases" => [
          {
            "databaseId" => "csc-scc",
            "name" => "Supreme Court of Canada",
            "jurisdiction" => "ca"
          },
          {
            "databaseId" => "onca",
            "name" => "Court of Appeal for Ontario",
            "jurisdiction" => "on"
          }
        ]
      }

      mock_client.expect :get, mock_response, ["/caseBrowse/en"]

      databases = CanLII::Database.with_client(mock_client) { CanLII::Database.all }

      assert_equal 2, databases.length
      assert_instance_of CanLII::Database, databases.first

      assert_equal "csc-scc", databases.first.database_id
      assert_equal "Supreme Court of Canada", databases.first.name
      assert_equal "ca", databases.first.jurisdiction

      assert_equal "onca", databases[1].database_id
      assert_equal "Court of Appeal for Ontario", databases[1].name
      assert_equal "on", databases[1].jurisdiction

      mock_client.verify
    end

    def test_all_handles_empty_response
      mock_client = Minitest::Mock.new
      mock_client.expect :get, { "caseDatabases" => [] }, ["/caseBrowse/en"]

      databases = CanLII::Database.with_client(mock_client) { CanLII::Database.all }

      assert_equal [], databases
      mock_client.verify
    end

    def test_all_handles_missing_case_databases_key
      mock_client = Minitest::Mock.new
      mock_client.expect :get, {}, ["/caseBrowse/en"]

      databases = CanLII::Database.with_client(mock_client) { CanLII::Database.all }

      assert_equal [], databases
      mock_client.verify
    end

    def test_all_uses_language_from_configuration
      CanLII.configuration.language = "fr"

      mock_client = Minitest::Mock.new
      mock_client.expect :get, { "caseDatabases" => [] }, ["/caseBrowse/fr"]

      databases = CanLII::Database.with_client(mock_client) { CanLII::Database.all }

      assert_equal [], databases
      mock_client.verify
    end

    def test_all_uses_default_client_when_called_without_with_client
      stub_request(:get, "https://api.canlii.org/v1/caseBrowse/en")
        .with(query: hash_including("api_key"))
        .to_return(
          status: 200,
          body: '{"caseDatabases": []}',
          headers: { "Content-Type" => "application/json" }
        )

      databases = CanLII::Database.all

      assert_equal [], databases
      assert_requested :get, "https://api.canlii.org/v1/caseBrowse/en",
                       query: hash_including("api_key")
    end

    def test_with_client_overrides_default_client
      mock_client = Minitest::Mock.new
      mock_client.expect :get, { "caseDatabases" => [] }, ["/caseBrowse/en"]

      result = CanLII::Database.with_client(mock_client) do
        CanLII::Database.all
      end

      assert_equal [], result
      mock_client.verify
    end

    def test_with_client_restores_previous_client_after_block
      initial_client = CanLII::Client.new
      Thread.current[:canlii_client] = initial_client

      temp_client = Minitest::Mock.new
      temp_client.expect :get, { "caseDatabases" => [] }, ["/caseBrowse/en"]

      CanLII::Database.with_client(temp_client) do
        CanLII::Database.all
      end

      assert_same initial_client, Thread.current[:canlii_client]
      temp_client.verify
    ensure
      Thread.current[:canlii_client] = nil
    end

    def test_with_client_restores_client_even_when_exception_occurs
      initial_client = CanLII::Client.new
      Thread.current[:canlii_client] = initial_client

      mock_client = Minitest::Mock.new
      mock_client.expect :get, nil do
        raise StandardError, "API error"
      end

      assert_raises(StandardError) do
        CanLII::Database.with_client(mock_client) do
          CanLII::Database.all
        end
      end

      assert_same initial_client, Thread.current[:canlii_client]
    ensure
      Thread.current[:canlii_client] = nil
    end
  end
end
