# frozen_string_literal: true

require "httparty"

require_relative "../base"
require_relative "./exceptions/invalid_api_key"
require_relative "./exceptions/invalid_database_id"
require_relative "./types/response"
require_relative "./helper"

module Fetcher
  module Notion
    ##
    # This class is an implementation of the Fetcher::Base interface, specifically designed
    # for fetching data from Notion.
    #
    class Base < Fetcher::Base
      NOTION_BASE_URL = "https://api.notion.com"

      protected

      # Implements the data fetching logic for data from Notion. It sends a POST
      # request to the Notion API to query the specified database and returns a validated response.
      #
      # <br>
      # <b>raises</b> <tt>Exceptions::Notion::InvalidApiKey</tt> if the API key provided is incorrect or invalid.
      #
      # <b>raises</b> <tt>Exceptions::Notion::InvalidDatabaseId</tt> if the Database id provided is incorrect
      # or invalid.
      #
      def execute(filter)
        url = "#{NOTION_BASE_URL}/v1/databases/#{config[:database_id]}/query"

        httparty_response = HTTParty.post(url, { body: filter.to_json, headers: headers })

        notion_response = Fetcher::Notion::Types::Response.new(httparty_response)

        Fetcher::Notion::Helper.validate_response(notion_response)
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
