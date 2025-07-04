# frozen_string_literal: true

module CanLII
  class Base
    include ActiveModel::Model
    include ActiveModel::Attributes

    class << self
      def with_client(client = nil)
        old_client = Thread.current[:canlii_client]

        if client
          Thread.current[:canlii_client] = client
          yield client
        else
          CanLII.configuration.validate!
          yield current_client
        end
      ensure
        Thread.current[:canlii_client] = old_client
      end

      private

      def current_client
        Thread.current[:canlii_client] || Client.new
      end
    end
  end
end
