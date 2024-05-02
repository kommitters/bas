# frozen_string_literal: true

require "json"

require_relative "./base"
require_relative "../utils/postgres/request"
require_relative "./types/response"

module Read
  ##
  # This class is an implementation of the Read::Base interface, specifically designed
  # to read from a PostgresDB used as <b>common storage</b>.
  #
  class Postgres < Read::Base
    # Execute the Postgres utility to read data from the <b>common storage</b>
    #
    def execute
      response = Utils::Postgres::Request.execute(params)

      records = response.values == [] ? nil : JSON.parse(response.values.first.first)

      Read::Types::Response.new(records)
    end

    private

    def params
      {
        connection: config[:connection],
        query: build_query
      }
    end

    def build_query
      query = "SELECT data FROM #{config[:db_table]} WHERE archived=$1 AND bot_name=$2 AND state=$3"
      params = [false, config[:bot_name], "success"]

      [query, params]
    end
  end
end