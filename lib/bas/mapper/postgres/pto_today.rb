# frozen_string_literal: true

require_relative "../../domain/pto"
require_relative "../base"

module Mapper
  module Postgres
    ##
    # This class implementats the methods of the Mapper::Base module, specifically designed for preparing or
    # shaping PTO's data coming from the Read::Postgres::Pto class.
    #
    class PtoToday
      # Implements the logic for shaping the results from a reader response.
      #
      # <br>
      # <b>Params:</b>
      # * <tt>Read::Postgres::Types::Response</tt> pg_response: Postgres response object.
      #
      # <br>
      # <b>returns</b> <tt>List<Domain::Pto></tt> ptos_list, mapped PTO's to be used by a Formatter::Base
      # implementation.
      #
      def map(pg_response)
        return [] if pg_response.records.empty?

        ptos = build_map(pg_response)

        ptos.map do |pto|
          name = pto["name"]
          start_date = { from: pto["start_date"], to: nil }
          end_date = { from: pto["end_date"], to: nil }

          Domain::Pto.new(name, start_date, end_date)
        end
      end

      private

      def build_map(pg_response)
        fields = pg_response.fields
        values = pg_response.records

        values.map { |value| Hash[fields.zip(value)] }
      end
    end
  end
end
