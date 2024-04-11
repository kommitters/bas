# frozen_string_literal: true

require "pg"

require_relative "../base"
require_relative "./types/response"
require_relative "./helper"

module Read
  module Postgres
    ##
    # This class is an implementation of the Read::Base interface, specifically designed
    # for reading data from Postgres.
    #
    class Base < Read::Base
      protected

      # Implements the read logic from a Postgres database. It use the PG gem
      # to request data from a local or external database and returns a validated response.
      #
      # Gem: pg (https://rubygems.org/gems/pg)
      #
      def read(query)
        pg_connection = PG::Connection.new(config[:connection])

        pg_result = execute_query(pg_connection, query)

        postgres_response = Read::Postgres::Types::Response.new(pg_result)

        Read::Postgres::Helper.validate_response(postgres_response)
      end

      private

      def execute_query(pg_connection, query)
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
