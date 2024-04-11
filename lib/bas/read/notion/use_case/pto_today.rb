# frozen_string_literal: true

require_relative "../base"

module Read
  module Notion
    ##
    # This class is an implementation of the Read::Notion::Base interface, specifically designed
    # for reading Paid Time Off (PTO) data from Notion.
    #
    class PtoToday < Notion::Base
      # Implements the reading filter for todays PTO's data from Notion.
      #
      def execute
        today = Time.now.utc.strftime("%F").to_s

        filter = {
          filter: {
            "and": [
              { property: "Desde?", date: { on_or_before: today } },
              { property: "Hasta?", date: { on_or_after: today } }
            ]
          }
        }

        read(filter)
      end
    end
  end
end
