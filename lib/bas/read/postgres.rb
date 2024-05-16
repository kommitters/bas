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
        data = JSON.parse(response.values.first.first)
        inserted_at = response.values.first.last
      end

      Read::Types::Response.new(data, inserted_at)
    end

    private

    def params
      {
        connection: config[:connection],
        query: build_query
      }
    end

    def build_query
      where = "archived=$1 AND bot_name=$2 AND state=$3 ORDER BY inserted_at DESC"
      params = [false, config[:bot_name], "success"]

      query = "SELECT data, inserted_at FROM #{config[:db_table]} WHERE #{where}"

      [query, params]
    end
  end
end
