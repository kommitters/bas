# frozen_string_literal: true

require "json"

require_relative "./base"
require_relative "../utils/postgres/request"
require_relative "./types/response"

module Read
  class Postgres < Read::Base
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
