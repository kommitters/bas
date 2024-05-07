# frozen_string_literal: true

require "httparty"

module Utils
  module Discord
    ##
    # This module is a Discord utility for sending messages to Discord.
    #
    module Integration
      # Implements the sending process logic to Discord. It sends a POST request to
      # the Discord webhook with the specified payload.
      #
      # <br>
      # <b>Params:</b>
      # * <tt>webhook</tt> Discord webhook integration.
      # * <tt>name</tt> Name of the discord user to send the message.
      # * <tt>notification</tt> Text of the notification to be sent.
      #
      # <br>
      # <b>returns</b> <tt>HTTParty::Response</tt>
      #
      def self.execute(params)
        HTTParty.post(params[:webhook], { body: body(params), headers: })
      end

      # Request body
      #
      def self.body(params)
        {
          username: params[:name],
          content: params[:notification]
        }.to_json
      end

      # Request headers
      #
      def self.headers
        { "Content-Type" => "application/json" }
      end
    end
  end
end
