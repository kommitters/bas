# frozen_string_literal: true

require "httparty"
require_relative "request"

module Utils
  module Notion
    ##
    # This module is a Notion utility for fetching record from a database.
    #
    class FetchDatabaseRecord
      # Implements the fetch page process logic to Notion.
      #
      # <br>
      # <b>Params:</b>
      # * <tt>database_id</tt> Id of the notion database.
      # * <tt>secret</tt> Notion secret.
      # * <tt>body</tt> Body with the filters.
      #
      # <br>
      # <b>returns</b> <tt>HTTParty::Response</tt>
      #
      #
      def initialize(options)
        @options = options
      end

      def execute
        records = Utils::Notion::Request.execute(params)

        records.parsed_response["results"] || []
      end

      private

      def params
        {
          endpoint: "databases/#{@options[:database_id]}/query",
          secret: @options[:secret],
          method: "post",
          body: @options[:body]
        }
      end
    end
  end
end
