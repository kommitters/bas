# frozen_string_literal: true

require_relative "../base"

module Read
  module Notion
    ##
    # This class is an implementation of the Read::Notion::Base interface, specifically designed
    # for counting "in progress" work items from work item database in Notion.
    #
    class WorkItemsLimit < Notion::Base
      # Implements the data reading count of "in progress" work items from Notion.
      #
      def execute
        filter = {
          filter: {
            "and": [
              { property: "OK", formula: { string: { contains: "✅" } } },
              { "or": status_conditions }
            ]
          }
        }

        read(filter)
      end

      private

      def status_conditions
        [
          { property: "Status", status: { equals: "In Progress" } },
          { property: "Status", status: { equals: "On Hold" } }
        ]
      end
    end
  end
end
