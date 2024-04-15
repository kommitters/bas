# frozen_string_literal: true

require_relative "../base"
require_relative "./exceptions/invalid_webhook_token"
require_relative "./types/response"

module Process
  module Discord
    ##
    # This class is an implementation of the Process::Base interface, specifically designed
    # for sending messages to Discord.
    #
    class Implementation < Base
      # Implements the sending process logic for the Discord use case. It sends a POST request to
      # the Discord webhook with the specified payload.
      #
      # <br>
      # <b>Params:</b>
      # * <tt>String</tt> payload: Payload to be send to discord.
      # <br>
      # <b>raises</b> <tt>Exceptions::Discord::InvalidWebookToken</tt> if the provided webhook token is invalid.
      #
      # <br>
      # <b>returns</b> <tt>Process::Discord::Types::Response</tt>
      #
      def execute(payload)
        body = {
          username: name,
          avatar_url: "",
          content: payload
        }.to_json
        response = HTTParty.post(webhook, { body: body, headers: { "Content-Type" => "application/json" } })

        discord_response = Process::Discord::Types::Response.new(response)

        validate_response(discord_response)
      end

      private

      def validate_response(response)
        case response.code
        when 50_027
          raise Discord::Exceptions::InvalidWebookToken, response.message
        else
          response
        end
      end
    end
  end
end
