# frozen_string_literal: true

require_relative "../base"

module Read
  module Notion
    ##
    # This class is an implementation of the Read::Notion::Base interface, specifically designed
    # for reading Notification data from Notion.
    #
    class Notification < Notion::Base
      # Implements the reading filter for notification data from Notion.
      #
      def execute
        filter = {
          filter: {
            property: "Use Case",
            title: {
              equals: config[:use_case_title]
            }
          }
        }

        read(filter)
      end
    end
  end
end
