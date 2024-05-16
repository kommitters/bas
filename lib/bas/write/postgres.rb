# frozen_string_literal: true

require_relative "./base"
require_relative "../version"
require_relative "../utils/postgres/request"

module Write
  ##
  # This class is an implementation of the Write::Base interface, specifically designed
  # to wtite to a PostgresDB used as <b>common storage</b>.
  #
  class Postgres < Write::Base
    PTO_PARAMS = "data, tag, archived, stage, status, version"

    # Execute the Postgres utility to write data in the <b>common storage</b>
    #
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
        [process_response[:success].to_json, config[:tag], false, "unprocessed", success_status, Bas::VERSION]
      else
        [nil, config[:tag], false, "unprocessed", process_response[:error].to_json, Bas::VERSION]
      end
    end

    def success_status
      { status: "success" }.to_json
    end
  end
end
