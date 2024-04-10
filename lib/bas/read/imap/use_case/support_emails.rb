# frozen_string_literal: true

require_relative "../base"

module Read
  module Imap
    ##
    # This class is an implementation of the Read::Imap::Base interface, specifically designed
    # for reading support email from a Google Gmail account.
    #
    class SupportEmails < Imap::Base
      TOKEN_URI = "https://oauth2.googleapis.com/token"
      EMAIL_DOMAIN = "imap.gmail.com"
      EMAIL_PORT = 993

      # Implements the data reading filter for support emails from Google Gmail.
      #
      def execute
        yesterday = (Time.now - (60 * 60 * 24)).strftime("%d-%b-%Y")
        query = ["TO", config[:search_email], "SINCE", yesterday]

        read(EMAIL_DOMAIN, EMAIL_PORT, TOKEN_URI, query)
      end
    end
  end
end
