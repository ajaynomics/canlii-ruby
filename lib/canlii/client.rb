# frozen_string_literal: true

module CanLII
  class Client
    def get(path, params = {})
      params = params.merge(api_key: config.api_key, language: config.language)

      http_client = HTTP
      http_client = http_client.timeout(config.timeout) if config.timeout

      response = http_client.get(build_url(path), params: params)
      handle_response(response)
    end

    private

    def build_url(path)
      "#{config.base_url}#{path}"
    end

    def handle_response(response)
      case response.status
      when 200..299
        JSON.parse(response.body.to_s)
      when 401, 403
        raise AuthenticationError, "Invalid API key"
      when 404
        raise NotFoundError, "Resource not found"
      when 429
        raise RateLimitError, "Rate limit exceeded"
      when 500..599
        raise ResponseError, "Server error: HTTP #{response.status}"
      else
        raise ResponseError, "HTTP #{response.status}: #{response.body}"
      end
    rescue HTTP::TimeoutError
      raise TimeoutError, "Request timed out after #{config.timeout} seconds"
    rescue HTTP::Error => e
      raise ConnectionError, "Network error: #{e.message}"
    rescue JSON::ParserError => e
      raise ResponseError, "Invalid JSON response: #{e.message}"
    end

    def config
      CanLII.configuration
    end
  end
end
