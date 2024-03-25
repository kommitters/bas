# frozen_string_literal: true

require_relative "../base"

module Fetcher
  module Notion
    ##
    # This class is an implementation of the Fetcher::Notion::Base interface, specifically designed
    # for fetching next week birthdays data from Notion.
    #
    class BirthdayNextWeek < Notion::Base
      DAYS_BEFORE_NOTIFY = 8

      # Implements the data fetching filter for next week Birthdays data from Notion.
      #
      def fetch
        filter = {
          filter: {
            or: [
              { property: "BD_this_year", date: { equals: eight_days_from_now } }
            ]
          }
        }

        execute(filter)
      end

      private

      def eight_days_from_now
        date = Time.now.utc + days_in_second(DAYS_BEFORE_NOTIFY)

        date.utc.strftime("%F").to_s
      end

      def days_in_second(days)
        days * 24 * 60 * 60
      end
    end
  end
end
