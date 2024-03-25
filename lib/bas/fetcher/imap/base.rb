# frozen_string_literal: true

require "net/imap"
require "gmail_xoauth"

require_relative "../base"
require_relative "./types/response"

module Fetcher
  module Imap
    ##
    # This class is an implementation of the Fetcher::Base interface, specifically designed
    # for fetching data from an IMAP server.
    #
    class Base < Fetcher::Base
      protected

      # Implements the data fetching logic for emails data from an IMAP server.
      # It connects to an IMAP server inbox, request emails base on a filter,
      # and returns a validated response.
      #
      def execute(email_domain, email_port, token_uri, query)
        access_token = refresh_token(token_uri)

        imap_fetch(email_domain, email_port, query, access_token)

        Fetcher::Imap::Types::Response.new(@emails)
      end

      private

      def imap_fetch(email_domain, email_port, query, access_token)
        imap = Net::IMAP.new(email_domain, port: email_port, ssl: true)

        imap.authenticate("XOAUTH2", config[:user], access_token)

        imap.examine(config[:inbox])

        @emails = fetch_emails(imap, query)

        imap.logout
        imap.disconnect
      end

      def fetch_emails(imap, query)
        imap.search(query).map do |message_id|
          imap.fetch(message_id, "ENVELOPE")[0].attr["ENVELOPE"]
        end
      end

      def refresh_token(token_uri)
        uri = URI.parse(token_uri)

        response = Net::HTTP.post_form(uri, params)
        token_data = JSON.parse(response.body)

        token_data["access_token"]
      end

      def params
        {
          "grant_type" => "refresh_token",
          "refresh_token" => config[:refresh_token],
          "client_id" => config[:client_id],
          "client_secret" => config[:client_secret]
        }
      end
    end
  end
end
