# frozen_string_literal: true

require "test_helper"

module CanLII
  class ConfigurationTest < CanLII::TestCase
    def test_default_configuration
      config = CanLII::Configuration.new
      
      assert_equal "https://api.canlii.org/v1", config.base_url
      assert_equal "en", config.language
      assert_nil config.api_key # ENV["CANLII_API_KEY"] is not set in tests
      assert_instance_of Logger, config.logger
    end

    def test_validates_presence_of_api_key
      config = CanLII::Configuration.new
      
      # Test nil
      config.api_key = nil
      assert_error_raised(CanLII::Error, "API key is required") do
        config.validate!
      end
      
      # Test empty string
      config.api_key = ""
      assert_error_raised(CanLII::Error, "API key is required") do
        config.validate!
      end
      
      # Test whitespace only
      config.api_key = "   "
      assert_error_raised(CanLII::Error, "API key is required") do
        config.validate!
      end
      
      # Test valid key
      config.api_key = "valid_key"
      assert_nil config.validate!
    end

    def test_configuration_is_mutable
      config = CanLII::Configuration.new
      
      config.api_key = "new_key"
      config.base_url = "https://api.example.com"
      config.language = "fr"
      config.logger = nil
      
      assert_equal "new_key", config.api_key
      assert_equal "https://api.example.com", config.base_url
      assert_equal "fr", config.language
      assert_nil config.logger
    end

    def test_global_configuration
      original_key = CanLII.configuration.api_key
      
      CanLII.configure do |config|
        config.api_key = "global_key"
        config.language = "fr"
      end
      
      assert_equal "global_key", CanLII.configuration.api_key
      assert_equal "fr", CanLII.configuration.language
    ensure
      CanLII.configuration.api_key = original_key
      CanLII.configuration.language = "en"
    end
  end
end