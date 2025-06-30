# frozen_string_literal: true

require "test_helper"

module CanLII
  class ConfigurationTest < CanLII::TestCase
    def test_default_configuration
      config = CanLII::Configuration.new

      assert_equal "https://api.canlii.org/v1", config.base_url
      assert_equal "en", config.language
      assert_nil config.api_key # ENV["CANLII_API_KEY"] is not set
      assert_instance_of Logger, config.logger
    end

    def test_configuration_validation
      config = CanLII::Configuration.new
      config.api_key = nil

      assert_raises(CanLII::Error) { config.validate! }

      config.api_key = "test_key"
      assert_nil config.validate!
    end
  end
end
