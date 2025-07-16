# frozen_string_literal: true

require "pg"

module Utils
  module Postgres
    # This module is a PostgresDB utility to manage the connection to the database.
    #
    class Connection
      def initialize(params)
        @connection = PG::Connection.new(params[:connection])
      end

      def query(query)
        results = if query.is_a? String
                    @connection.exec(query)
                  else
                    sentence, params = query

                    @connection.exec_params(sentence, params)
                  end

        results.map { |result| result.transform_keys(&:to_sym) }
      end

      def finish
        @connection&.finish
        @connection = nil
      end
    end
  end
end
