# frozen_string_literal: true

require_relative "../base"

module Fetcher
  module Notion
    ##
    # This class is an implementation of the Fetcher::Notion::Base interface, specifically designed
    # for fetching birthday data from Notion.
    #
    class BirthdayToday < Notion::Base
      # Implements the data fetching filter for todays Birthdays data from Notion.
      #
      def fetch
        today = Time.now.utc.strftime("%F").to_s

        filter = {
          filter: {
            or: [
              { property: "BD_this_year", date: { equals: today } }
            ]
          }
        }

        execute(filter)
      end
    end
  end
end
