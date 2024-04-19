# frozen_string_literal: true

require_relative "../../domain/notification"
require_relative "../base"

module Serialize
  module Notion
    ##
    # This class implements the methods of the Serialize::Base module, specifically designed for preparing or
    # shaping Notification's data coming from a Read::Base implementation.
    #
    class Notification
      include Base

      NOTIFICATION_PARAMS = ["Notification"].freeze

      # Implements the logic for shaping the results from a reader response.
      #
      # <br>
      # <b>Params:</b>
      # * <tt>Read::Notion::Types::Response</tt> notion_response: Notion response object.
      #
      # <br>
      # <b>returns</b> <tt>List<Domain::Notification></tt> notification_list, serialized
      # notifications to be used by a Formatter::Base implementation.
      #
      def execute(notion_response)
        return [] if notion_response.results.empty?

        normalized_notion_data = normalize_response(notion_response.results)

        normalized_notion_data.map do |notification|
          Domain::Notification.new(notification["Notification"])
        end
      end

      private

      def normalize_response(response)
        return [] if response.nil?

        response.map do |value|
          notification_fields = value["properties"].slice(*NOTIFICATION_PARAMS)

          {
            "Notification" => extract_notification_field_value(notification_fields["Notification"])
          }
        end
      end

      def extract_notification_field_value(notification)
        notification["rich_text"][0]["plain_text"]
      end
    end
  end
end
