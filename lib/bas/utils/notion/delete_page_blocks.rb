# frozen_string_literal: true

require "httparty"
require_relative "request"

module Utils
  module Notion
    ##
    # This module is a Notion utility for deleting page blocks.
    #
    class DeletePageBlocks
      # Implements the delete page blocks process logic to Notion.
      #
      # <br>
      # <b>Params:</b>
      # * <tt>page_id</tt> Id of the notion page.
      # * <tt>secret</tt> Notion secret.
      #
      # <br>
      # <b>returns</b> <tt>HTTParty::Response</tt>
      #
      #
      def initialize(params)
        @params = params
      end

      def execute
        page_blocks_ids.each { |block_id| delete_block(block_id) }
      end

      private

      def page_blocks_ids
        page = Utils::Notion::Request.execute(page_params)

        page.parsed_response["results"].map { |block| block["id"] }
      end

      def page_params
        {
          endpoint: "blocks/#{@params[:page_id]}/children",
          secret: @params[:secret],
          method: "get",
          body: {}
        }
      end

      def delete_block(block_id)
        params = delete_params(block_id)

        Utils::Notion::Request.execute(params)
      end

      def delete_params(block_id)
        {
          endpoint: "blocks/#{block_id}",
          secret: @params[:secret],
          method: "delete",
          body: {}
        }
      end
    end
  end
end
