# frozen_string_literal: true

require "httparty"
require_relative "request"

module Utils
  module Notion
    ##
    # This module is a Notion utility for updating database properties.
    #
    class UpdateDatabasePage
      # Implements the update database properties process logic to Notion.
      #
      # <br>
      # <b>Params:</b>
      # * <tt>page_id</tt> Id of the notion page.
      # * <tt>secret</tt> Notion secret.
      # * <tt>body</tt> Request body with the properties to be updated.
      #
      # <br>
      # <b>returns</b> <tt>HTTParty::Response</tt>
      #
      #
      def initialize(options)
        @options = options
      end

      def execute
        Utils::Notion::Request.execute(params)
      end

      private

      def params
        {
          endpoint: "pages/#{@options[:page_id]}",
          secret: @options[:secret],
          method: "patch",
          body: @options[:body]
        }
      end
    end
  end
end
