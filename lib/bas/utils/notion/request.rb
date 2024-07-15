# frozen_string_literal: true

require "httparty"
require "json"

module Utils
  module Notion
    ##
    # This module is a Notion utility for sending request to create, update, or delete
    # Notion resources.
    #
    module Request
      NOTION_BASE_URL = "https://api.notion.com/v1"

      # Implements the request process logic to Notion.
      #
      # <br>
      # <b>Params:</b>
      # * <tt>method</tt> HTTP request method: post, get, put, etc.
      # * <tt>body</tt> Request body (Hash).
      # * <tt>endpoint</tt> Notion resource endpoint.
      # * <tt>secret</tt> Notion secret.
      #
      # <br>
      # <b>returns</b> <tt>HTTParty::Response</tt>
      #
      def self.execute(params)
        url = "#{NOTION_BASE_URL}/#{params[:endpoint]}"

        headers = notion_headers(params[:secret])

        HTTParty.send(params[:method], url, { body: params[:body].to_json, headers: })
      end

      # Request headers
      #
      def self.notion_headers(secret)
        {
          "Authorization" => "Bearer #{secret}",
          "Content-Type" => "application/json",
          "Notion-Version" => "2022-06-28"
        }
      end
    end
  end
end
