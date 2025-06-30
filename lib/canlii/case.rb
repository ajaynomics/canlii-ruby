# frozen_string_literal: true

module CanLII
  class Case < Base
    attribute :database_id, :string
    attribute :case_id, :string
    attribute :title, :string
    attribute :citation, :string
    attribute :url, :string
    attribute :decision_date, :date
    attribute :language, :string

    class << self
      def browse(database_id, **options)
        with_client do |client|
          params = build_browse_params(options)
          response = client.get("/caseBrowse/#{language}/#{database_id}", params)

          return [] if response.is_a?(Array)

          cases = response["cases"] || []
          cases.map { |data| new_from_browse(data) }
        end
      end

      def find(database_id, case_id)
        with_client do |client|
          response = client.get("/caseBrowse/#{language}/#{database_id}/#{case_id}")
          new_from_detail(response)
        end
      rescue NotFoundError
        nil
      end

      def find!(database_id, case_id)
        find(database_id, case_id) ||
          raise(NotFoundError, "Case not found: #{database_id}/#{case_id}")
      end

      private

      def new_from_browse(data)
        case_id_obj = data["caseId"]
        case_id_value = case_id_obj.is_a?(Hash) ? case_id_obj["en"] : case_id_obj

        new(
          database_id: data["databaseId"],
          case_id: case_id_value,
          title: data["title"],
          citation: data["citation"],
          decision_date: data["decisionDate"]
        )
      end

      def new_from_detail(data)
        new(
          database_id: data["databaseId"],
          case_id: data["caseId"],
          title: data["title"],
          citation: data["citation"],
          url: data["url"],
          decision_date: data["decisionDate"],
          language: data["language"]
        )
      end

      def build_browse_params(options)
        params = {}
        params[:offset] = options[:offset] || 0
        params[:resultCount] = options[:limit] || 20

        params[:decisionDateAfter] = options[:published_after].to_s if options[:published_after]

        params[:decisionDateBefore] = options[:published_before].to_s if options[:published_before]

        params
      end

      def language
        CanLII.configuration.language
      end
    end

    def to_s
      citation || title || "#{database_id}/#{case_id}"
    end
  end
end
