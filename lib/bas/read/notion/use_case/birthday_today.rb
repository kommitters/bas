# frozen_string_literal: true

require_relative "../base"

module Read
  module Notion
    ##
    # This class is an implementation of the Read::Notion::Base interface, specifically designed
    # for reading birthday data from Notion.
    #
    class BirthdayToday < Notion::Base
      # Implements the reading filter for todays Birthdays data from Notion.
      #
      def execute
        today = Time.now.utc.strftime("%F").to_s

        filter = {
          filter: {
            or: [
              { property: "BD_this_year", date: { equals: today } }
            ]
          }
        }

        read(filter)
      end
    end
  end
end
