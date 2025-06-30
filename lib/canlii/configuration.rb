# frozen_string_literal: true

module CanLII
  class Configuration
    attr_accessor :api_key, :base_url, :language, :logger

    def initialize
      @base_url = "https://api.canlii.org/v1"
      @language = "en"
      @api_key = ENV["CANLII_API_KEY"]
      @logger = Logger.new($stdout)
    end

    def validate!
      raise Error, "API key is required" if api_key.blank?
    end
  end
end
