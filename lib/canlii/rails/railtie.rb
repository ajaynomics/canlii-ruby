# frozen_string_literal: true

module CanLII
  module Rails
    class Railtie < ::Rails::Railtie
      initializer "canlii.logger" do |_app|
        CanLII.configuration.logger = ::Rails.logger
      end
    end
  end
end
