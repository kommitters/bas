# frozen_string_literal: true

require_relative "../base"

module Fetcher
  module Notion
    ##
    # This class is an implementation of the Fetcher::Notion::Base interface, specifically designed
    # for fetching next week Paid Time Off (PTO) data from Notion.
    #
    class PtoNextWeek < Notion::Base
      # Implements the data fetching filter for next week PTO's data from Notion.
      #
      def fetch
        filter = build_filter

        execute(filter)
      end

      private

      def next_week_dates
        monday = next_week_monday
        sunday = monday + 6

        [monday, sunday]
      end

      def next_week_monday
        today = Date.today
        week_day = today.wday

        days = week_day.zero? ? 1 : 8 - week_day

        today + days
      end

      def build_filter
        monday, sunday = next_week_dates

        {
          filter: {
            or: [
              belong_next_week("Desde?", monday, sunday),
              belong_next_week("Hasta?", monday, sunday),
              cover_next_week(monday, sunday)
            ]
          }
        }
      end

      def belong_next_week(property, after_day, before_day)
        {
          and: [
            { property: property, date: { on_or_after: after_day } },
            { property: property, date: { on_or_before: before_day } }
          ]
        }
      end

      def cover_next_week(monday, sunday)
        {
          and: [
            { property: "Hasta?", date: { on_or_after: sunday } },
            { property: "Desde?", date: { on_or_before: monday } }
          ]
        }
      end
    end
  end
end
