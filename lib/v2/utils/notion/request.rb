# frozen_string_literal: true

require "httparty"

module Utils
  module Notion
    module Request
      NOTION_BASE_URL = "https://api.notion.com/v1"

      def self.execute(params)
        url = "#{NOTION_BASE_URL}/#{params[:endpoint]}"

        headers = notion_headers(params[:secret])

        HTTParty.send(params[:method], url, { body: params[:filter].to_json, headers: })
      end

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
