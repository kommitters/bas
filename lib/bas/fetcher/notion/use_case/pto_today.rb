# frozen_string_literal: true

require_relative "../base"

module Fetcher
  module Notion
    ##
    # This class is an implementation of the Fetcher::Notion::Base interface, specifically designed
    # for fetching Paid Time Off (PTO) data from Notion.
    #
    class PtoToday < Notion::Base
      # Implements the data fetching filter for todays PTO's data from Notion.
      #
      def fetch
        today = Time.now.utc.strftime("%F").to_s

        filter = {
          filter: {
            "and": [
              { property: "Desde?", date: { on_or_before: today } },
              { property: "Hasta?", date: { on_or_after: today } }
            ]
          }
        }

        execute(filter)
      end
    end
  end
end
