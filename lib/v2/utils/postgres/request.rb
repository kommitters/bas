# frozen_string_literal: true

require "pg"

module Utils
  module Postgres
    ##
    # This module is a PostgresDB utility to make requests to a Postgres database.
    #
    module Request
      # Implements the request process logic to the PostgresDB table.
      #
      # <br>
      # <b>Params:</b>
      # * <tt>connection</tt> Connection parameters to the database: `host`, `port`, `dbname`, `user`, `password`.
      # * <b>query</b>:
      #   * <tt>String</tt>: String with the SQL query to be executed.
      #   * <tt>Array</tt>: Two element array, where the first element is the SQL query (string), and the
      #                     second one an array of elements to be interpolared in the query when using "$1, $2, ...".
      #
      # <br>
      # <b>returns</b> <tt>HTTParty::Response</tt>
      #
      def self.execute(params)
        pg_connection = PG::Connection.new(params[:connection])

        execute_query(pg_connection, params[:query])
      end

      # Execute the Postgres query
      #
      # <br>
      # <b>pg_connection</b>: PG::Connection object configured with the database connection.
      # <b>query</b>:
      # * <tt>String</tt>: String with the SQL query to be executed.
      # * <tt>Array</tt>: Two element array, where the first element is the SQL query (string), and the
      #                   second one an array of elements to be interpolared in the query when using "$1, $2, ...".
      #
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
