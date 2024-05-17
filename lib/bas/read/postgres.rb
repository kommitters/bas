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

      unless response.values == []
        id = response.values.first[0]
        data = JSON.parse(response.values.first[1])
        inserted_at = response.values.first[2]
      end

      Read::Types::Response.new(id, data, inserted_at)
    end

    private

    def params
      {
        connection: config[:connection],
        query: build_query
      }
    end

    def build_query
      where = "archived=$1 AND tag=$2 AND stage=$3 ORDER BY inserted_at ASC"
      params = [false, config[:tag], "unprocessed"]
      query = "SELECT id, data, inserted_at FROM #{config[:db_table]} WHERE #{where}"

      [query, params]
    end
  end
end
