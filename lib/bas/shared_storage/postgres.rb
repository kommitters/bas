# frozen_string_literal: true

require_relative "base"
require_relative "types/read"
require_relative "../utils/postgres/connection"
require_relative "../version"

require "json"

module Bas
  module SharedStorage
    ##
    # The SharedStorage::Postgres class serves as a shared storage implementation to read and write on
    # a shared storage defined as a postgres database
    #
    class Postgres < Bas::SharedStorage::Base
      TABLE_PARAMS = "data, tag, archived, stage, status, error_message, version"

      def read
        establish_connection(:read)

        first_result = @read_connection.query(read_query).first || {}

        @read_response = Bas::SharedStorage::Types::Read.new(first_result[:id], first_result[:data],
                                                             first_result[:inserted_at])
      end

      def write(data)
        establish_connection(:write)

        @write_response = @write_connection.query(write_query(data))
      end

      def close_connections
        @read_connection&.finish
        @write_connection&.finish
        @read_connection = nil
        @write_connection = nil
      end

      def set_in_process
        return if read_options[:avoid_process].eql?(true) || read_response.id.nil?

        update_stage(read_response.id, "in process")
      end

      def set_processed
        return if read_options[:avoid_process].eql?(true) || read_response.id.nil?

        update_stage(read_response.id, "processed") unless @read_response.nil?
      end

      private

      def establish_connection(action)
        case action
        when :read
          @read_connection ||= Utils::Postgres::Connection.new(read_options[:connection])
        when :write
          @write_connection ||= Utils::Postgres::Connection.new(write_options[:connection])
        end
      end

      def read_query
        query = "SELECT id, data, inserted_at FROM #{read_options[:db_table]} WHERE status='success' AND #{where}"

        [query, where_params]
      end

      def write_query(data)
        query = "INSERT INTO #{write_options[:db_table]} (#{TABLE_PARAMS}) VALUES ($1, $2, $3, $4, $5, $6, $7);"
        params = write_params(data)

        [query, params]
      end

      def where
        return read_options[:where] unless read_options[:where].nil?

        "archived=$1 AND tag=$2 AND stage=$3 ORDER BY inserted_at ASC"
      end

      def where_params
        return read_options[:params] unless read_options[:params].nil?

        [false, read_options[:tag], "unprocessed"]
      end

      def write_params(data)
        if data[:success]
          [data[:success].to_json, write_options[:tag], false, "unprocessed", "success", nil, Bas::VERSION]
        else
          [nil, write_options[:tag], false, "unprocessed", "failed", data[:error].to_json, Bas::VERSION]
        end
      end

      def update_stage(id, stage)
        establish_connection(:read)

        @read_connection.query(update_query(id, stage))
      end

      def update_query(id, stage)
        query = "UPDATE #{read_options[:db_table]} SET stage=$1 WHERE id=$2"
        values = [stage, id]

        [query, values]
      end
    end
  end
end
