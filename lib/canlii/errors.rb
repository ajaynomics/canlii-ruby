# frozen_string_literal: true

module CanLII
  # Base error class for all CanLII errors
  class Error < StandardError; end

  # Raised when API key is invalid or missing
  class AuthenticationError < Error; end

  # Raised when requested resource doesn't exist
  class NotFoundError < Error; end

  # Raised when API rate limit is exceeded
  class RateLimitError < Error; end

  # Raised when request times out
  class TimeoutError < Error; end

  # Raised when connection fails
  class ConnectionError < Error; end

  # Raised for other HTTP errors
  class ResponseError < Error; end
end
