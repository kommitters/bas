# frozen_string_literal: true

require_relative './base'
require_relative '../utils/postgres/request'

module Write
  class Postgres < Write::Base
    PTO_PARAMS = "data, bot_name, archived, state, error_message, version"

    def execute
      Utils::Postgres::Request.execute(params)
    end

    private

    def params
      {
        connection: config[:connection],
        query: build_query
      }
    end

    def build_query
      query = "INSERT INTO #{config[:db_table]} (#{PTO_PARAMS}) VALUES ($1, $2, $3, $4, $5, $6);"
      params = [data, config[:bot_name], false, "success", nil, 1]

      [query, params]
    end

    def data
      {
        data: process_response.data
      }.to_json
    end
  end
end
