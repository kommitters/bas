# frozen_string_literal: true

require_relative "base"
require_relative "types/read"
require_relative "../utils/elasticsearch/request"
require_relative "../version"

module Bas
  module SharedStorage
    ##
    # The SharedStorage::Elasticsearch class serves as a shared storage implementation to read and write on
    # a shared storage defined as a elasticsearch database
    #
    class Elasticsearch < Bas::SharedStorage::Base
      def read
        params = {
          connection: read_options[:connection], index: read_options[:index],
          query: read_body, method: :search
        }

        result = Utils::Elasticsearch::Request.execute(params)
        @read_response = build_read_response(result)
      end

      def write(data)
        params = {
          connection: write_options[:connection],
          index: write_options[:index],
          body: write_body(data),
          method: :index
        }

        create_mapping
        @write_response = Utils::Elasticsearch::Request.execute(params).body
      end

      def set_in_process
        return if read_options[:avoid_process].eql?(true) || read_response.id.nil?

        update_stage(read_response.id, "in process")
      end

      def set_processed
        return if read_options[:avoid_process].eql?(true) || read_response.id.nil?

        update_stage(read_response.id, "processed")
      end

      private

      # rubocop:disable Metrics/MethodLength
      def create_mapping
        params = {
          connection: write_options[:connection],
          index: write_options[:index],
          body: {
            mappings: {
              properties: {
                data: { type: "object" },
                tag: { type: "text" },
                archived: { type: "boolean" },
                inserted_at: { type: "date", format: "yyyy-MM-dd HH:mm:ss Z" },
                stage: { type: "text" },
                status: { type: "text" },
                error_message: { type: "object" },
                version: { type: "text" }
              }
            }
          },
          method: :create_mapping
        }

        Utils::Elasticsearch::Request.execute(params)
      end

      def read_body
        return read_options[:query] if read_options[:query].is_a?(Hash)

        {
          query: {
            bool: {
              must: [
                { match: { status: "success" } }, { match: { tag: read_options[:tag] } },
                { match: { archived: false } }, { match: { stage: "unprocessed" } }
              ]
            }
          },
          sort: [{ inserted_at: { order: "asc" } }]
        }
      end

      def write_body(data)
        if data[:success]
          return {
            data: data[:success], tag: write_options[:tag],
            archived: false, inserted_at: Time.now.strftime("%Y-%m-%d %H:%M:%S %z"),
            stage: "unprocessed", status: "success", error_message: nil, version: Bas::VERSION
          }
        end

        {
          data: nil, tag: write_options[:tag], archived: false,
          inserted_at: Time.now.strftime("%Y-%m-%d %H:%M:%S %z"), stage: "unprocessed",
          status: "failed", error_message: data[:error], version: Bas::VERSION
        }
      end
      # rubocop:enable Metrics/MethodLength

      def build_read_response(result)
        first_hit = result["hits"]["hits"].empty? ? {} : result["hits"]["hits"].first
        Bas::SharedStorage::Types::Read.new(
          first_hit["_id"], first_hit["_source"]["data"].to_json, first_hit.dig("_source", "inserted_at")
        )
      end

      def update_stage(id, stage)
        params = {
          connection: read_options[:connection], index: read_options[:index], method: :update,
          body: {
            query: { ids: { values: [id] } },
            script: { source: "ctx._source.stage = params.new_value", params: { new_value: stage } }
          }
        }

        response = Utils::Elasticsearch::Request.execute(params)
        return unless response["updated"].zero?

        raise StandardError, "Document with id #{id} not found, so it was not updated"
      end
    end
  end
end
