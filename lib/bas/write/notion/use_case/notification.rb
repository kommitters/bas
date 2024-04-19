# frozen_string_literal: true

require_relative "../base"

module Write
  module Notion
    ##
    # This class is an implementation of the Write::OpenAI::Base interface, specifically designed
    # to update an existing page on a Notion database to write the notification text.
    class Notification < Notion::Base
      # Implements the writting process logic for the Notification use case.
      #
      # <br>
      # <b>Params:</b>
      # * <tt>Process::Types::Response</tt> process response: standard process response with the data to be updated.
      #
      def execute(process_response)
        endpoint = "/v1/pages/#{config[:page_id]}"

        body = body(process_response.data.choices[0]["message"]["content"])

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
