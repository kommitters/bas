# frozen_string_literal: true

require_relative "../base"

module Fetcher
  module Postgres
    ##
    # This class is an implementation of the Fetcher::Postgres::Base interface, specifically designed
    # for fetching Paid Time Off (PTO) data from a Postgres Database.
    #
    class PtoToday < Base
      # Implements the data fetching query for todays PTO data from a Postgres database.
      #
      def fetch
        execute(build_query)
      end

      private

      def build_query
        today = Time.now.utc.strftime("%F").to_s

        start_time = "#{today}T00:00:00"
        end_time = "#{today}T23:59:59"

        where = "(start_date <= $1 AND end_date >= $1) OR (start_date>= $2 AND end_date <= $3)"

        ["SELECT * FROM pto WHERE #{where}", [today, start_time, end_time]]
      end
    end
  end
end
