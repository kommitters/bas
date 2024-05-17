# frozen_string_literal: true

require_relative "./base"
require_relative "../version"
require_relative "../utils/postgres/request"

module Write
  ##
  # This class is an implementation of the Write::Base interface, specifically designed
  # to update to a PostgresDB used as <b>common storage</b>.
  #
  class PostgresUpdate < Write::Base
    PTO_PARAMS = "data, tag, archived, stage, status, version"

    # Execute the Postgres utility to update data in the <b>common storage</b>
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
      params, values = build_params
      query = "UPDATE #{config[:db_table]} SET #{params} WHERE #{config[:conditions]}"

      [query, values]
    end

    def build_params
      params = ""
      values = []

      config[:params].each_with_index do |(param, value), idx|
        params += "#{param}=$#{idx + 1}"
        values << value
      end

      [params, values]
    end
  end
end
