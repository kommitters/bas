# frozen_string_literal: true

require_relative "../base"
require_relative "./exceptions/invalid_webhook_token"
require_relative "./types/response"

module Dispatcher
  module Slack
    ##
    # This class is an implementation of the Dispatcher::Base interface, specifically designed
    # for dispatching messages to Slack.
    #
    class Implementation < Base
      # Implements the dispatching logic for the Slack use case. It sends a POST request to
      # the Slack webhook with the specified payload.
      #
      # <br>
      # <b>Params:</b>
      # * <tt>String</tt> payload: Payload to be dispatched to slack.
      # <br>
      # <b>raises</b> <tt>Exceptions::Slack::InvalidWebookToken</tt> if the provided webhook token is invalid.
      #
      # <br>
      # <b>returns</b> <tt>Dispatcher::Slack::Types::Response</tt>
      #
      def dispatch(payload)
        body = {
          username: name,
          text: payload
        }.to_json

        response = HTTParty.post(webhook, { body: body, headers: { "Content-Type" => "application/json" } })

        slack_response = Dispatcher::Discord::Types::Response.new(response)

        validate_response(slack_response)
      end

      private

      def validate_response(response)
        case response.http_code
        when 403
          raise Dispatcher::Slack::Exceptions::InvalidWebookToken, response.message
        else
          response
        end
      end
    end
  end
end
