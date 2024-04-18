# frozen_string_literal: true

require_relative "../base"

module Write
  module Notion
    ##
    # This class is an implementation of the Write::Base interface, specifically designed
    # to create or update pages in a Notion database.
    #
    class Base < Write::Base
      NOTION_BASE_URL = "https://api.notion.com"

      protected

      # Implements the writing logic to create or update pages in a Notion.database. It sends
      # a request to the Notion API given the method (post, patch, etc), endpoint and body.
      #
      def write(method, endpoint, body)
        url = "#{NOTION_BASE_URL}#{endpoint}"

        HTTParty.send(method, url, { body: body.to_json, headers: })
      end

      private

      def headers
        {
          "Authorization" => "Bearer #{config[:secret]}",
          "Content-Type" => "application/json",
          "Notion-Version" => "2022-06-28"
        }
      end
    end
  end
end
