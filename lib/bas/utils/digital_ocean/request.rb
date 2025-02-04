# frozen_string_literal: true

require "httparty"
require "json"

module Utils
  module DigitalOcean
    ##
    # This module is a Notion utility for sending request to create, update, or delete
    # Notion resources.
    #
    module Request
      DIGITAL_OCEAN_BASE_URL = "https://api.digitalocean.com/v2"

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
        validate_params(params)

        url = "#{DIGITAL_OCEAN_BASE_URL}/#{params[:endpoint]}"
        headers = headers(params[:secret])
        body = params[:body]&.to_json

        HTTParty.send(params[:method], url, { body: body, headers: headers })
      end

      def self.headers(secret)
        {
          "Authorization" => "Bearer #{secret}",
          "Content-Type" => "application/json"
        }
      end

      def self.validate_params(params)
        raise ArgumentError, "Secret is required" unless params[:secret]
        raise ArgumentError, "Endpoint is required" unless params[:endpoint]
      end
    end
  end
end
