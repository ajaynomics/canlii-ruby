# frozen_string_literal: true

module CanLII
  class Configuration
    attr_accessor :api_key, :base_url, :language, :logger, :timeout

    def initialize
      @base_url = "https://api.canlii.org/v1"
      @language = "en"
      @api_key = ENV.fetch("CANLII_API_KEY", nil)
      @logger = Logger.new($stdout)
      @timeout = 30 # Default 30 seconds
    end

    def validate!
      raise Error, "API key is required" if api_key.nil? || api_key.to_s.strip.empty?
    end
  end
end
