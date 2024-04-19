# frozen_string_literal: true

require_relative "../base"

module Write
  module Notion
    ##
    # This class is an implementation of the Write::Notion::Base interface, specifically designed
    # to update an existing page in a Notion database to write an empty text.
    class EmptyNotification < Notion::Base
      # Implements the writting process logic for the Notification use case.
      #
      # <br>
      # <b>Params:</b>
      # * <tt>Process::Types::Response</tt> process response: standard process response.
      #
      def execute(_process_response)
        endpoint = "/v1/pages/#{config[:page_id]}"

        body = body("")

        write("patch", endpoint, body)
      end

      private

      def body(content)
        {
          properties: {
            Notification: {
              rich_text: [{ text: { content: } }]
            }
          }
        }
      end
    end
  end
end
