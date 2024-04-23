# frozen_string_literal: true

require "pg"

module Utils
  module Postgres
    module Request
      def self.execute(params)
        pg_connection = PG::Connection.new(params[:connection])

        execute_query(pg_connection, params[:query])
      end

      private

      def self.execute_query(pg_connection, query)
        if query.is_a? String
          pg_connection.exec(query)
        else
          sentence, params = query

          pg_connection.exec_params(sentence, params)
        end
      end
    end
  end
end
