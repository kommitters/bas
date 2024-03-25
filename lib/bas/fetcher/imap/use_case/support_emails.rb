# frozen_string_literal: true

require_relative "../base"

module Fetcher
  module Imap
    ##
    # This class is an implementation of the Fetcher::Imap::Base interface, specifically designed
    # for fetching support email from a Google Gmail account.
    #
    class SupportEmails < Imap::Base
      TOKEN_URI = "https://oauth2.googleapis.com/token"
      EMAIL_DOMAIN = "imap.gmail.com"
      EMAIL_PORT = 993

      # Implements the data fetching filter for support emails from Google Gmail.
      #
      def fetch
        yesterday = (Time.now - (60 * 60 * 24)).strftime("%e-%b-%Y")
        query = ["TO", config[:search_email], "SINCE", yesterday]

        execute(EMAIL_DOMAIN, EMAIL_PORT, TOKEN_URI, query)
      end
    end
  end
end
