# frozen_string_literal: true

require "active_model"
require "http"
require "json"
require "logger"

require_relative "canlii/version"
require_relative "canlii/errors"
require_relative "canlii/configuration"
require_relative "canlii/client"
require_relative "canlii/base"
require_relative "canlii/database"
require_relative "canlii/case"

module CanLII
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def with_language(language)
      old_language = configuration.language
      configuration.language = language
      yield
    ensure
      configuration.language = old_language
    end
  end
end

require_relative "canlii/rails/railtie" if defined?(Rails::Railtie)
