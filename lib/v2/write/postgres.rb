# frozen_string_literal: true

require_relative "./base"
require_relative "../utils/postgres/request"

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
      params = build_params

      [query, params]
    end

    def build_params
      if process_response[:success]
        [process_response[:success].to_json, config[:bot_name], false, "success", nil, 1]
      else
        [nil, config[:bot_name], false, "failed", process_response[:error].to_json, 1]
      end
    end
  end
end
