# frozen_string_literal: true

module CanLII
  class Database < Base
    attribute :database_id, :string
    attribute :name, :string
    attribute :jurisdiction, :string

    class << self
      def all
        with_client do |client|
          response = client.get("/caseBrowse/#{language}")
          databases = response["caseDatabases"] || []

          databases.map do |data|
            new(
              database_id: data["databaseId"],
              name: data["name"],
              jurisdiction: data["jurisdiction"]
            )
          end
        end
      end

      private

      def language
        CanLII.configuration.language
      end
    end
  end
end
