# frozen_string_literal: true

require "pg"

module Utils
  module Postgres
    # This module is a PostgresDB utility to establish connections to a Postgres database
    # and execute raw or parameterized queries.
    #
    class Connection
      def initialize(params)
        @connection = PG::Connection.new(params)
      end

      def query(query)
        results = if query.is_a? String
                    @connection.exec(query)
                  else
                    validate_query(query)

                    sentence, params = query
                    @connection.exec_params(sentence, params)
                  end

        results.map { |result| result.transform_keys(&:to_sym) }
      end

      def finish
        @connection&.finish
        @connection = nil
      end

      private

      def validate_query(query)
        return if query.is_a?(Array) && query.size == 2 && query[0].is_a?(String) && query[1].is_a?(Array)

        raise ArgumentError, "Parameterized query must be an array of [sentence (String), params (Array)]"
      end
    end
  end
end
