# frozen_string_literal: true

require "net/imap"
require "gmail_xoauth"
require "httparty"

module Utils
  module Imap
    ##
    # This module is a Imap utility for request emails from a Imap server
    #
    class Request
      def initialize(params, query)
        @refresh_token = params[:refresh_token]
        @client_id = params[:client_id]
        @client_secret = params[:client_secret]
        @token_uri = params[:token_uri]
        @email_domain = params[:email_domain]
        @email_port = params[:email_port]
        @user_email = params[:user_email]
        @inbox = params[:inbox]
        @query = query

        @emails = []
      end

      # Execute the imap requets after authenticate the email with the credentials
      #
      def execute
        response = refresh_token

        return { error: response } unless response["error"].nil?

        imap_fetch(response["access_token"])

        { emails: @emails }
      rescue StandardError => e
        { error: e.to_s }
      end

      private

      def imap_fetch(access_token)
        imap = Net::IMAP.new(@email_domain, port: @email_port, ssl: true)

        imap.authenticate("XOAUTH2", @user_email, access_token)

        imap.examine(@inbox)

        @emails = fetch_emails(imap)

        imap.logout
        imap.disconnect
      end

      def fetch_emails(imap)
        imap.search(@query).map do |message_id|
          { message_id:, message: imap.fetch(message_id, "ENVELOPE")[0].attr["ENVELOPE"] }
        end
      end

      def refresh_token
        HTTParty.post(@token_uri, { body: })
      end

      def body
        {
          "grant_type" => "refresh_token",
          "refresh_token" => @refresh_token,
          "client_id" => @client_id,
          "client_secret" => @client_secret
        }
      end
    end
  end
end
