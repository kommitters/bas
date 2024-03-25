# frozen_string_literal: true

require_relative "../../domain/email"
require_relative "../base"

module Mapper
  module Imap
    ##
    # This class implementats the methods of the Mapper::Base module, specifically designed for
    # preparing or shaping support emails data coming from a Fetcher::Base implementation.
    class SupportEmails
      include Base

      # Implements the logic for shaping the results from a fetcher response.
      #
      # <br>
      # <b>Params:</b>
      # * <tt>Fetcher::Imap::Types::Response</tt> imap_response: Array of imap emails data.
      #
      # <br>
      # <b>return</b> <tt>List<Domain::Email></tt> support_emails_list, mapped support emails to be used by a
      # Formatter::Base implementation.
      #
      def map(imap_response)
        return [] if imap_response.results.empty?

        normalized_email_data = normalize_response(imap_response.results)

        normalized_email_data.map do |email|
          Domain::Email.new(email["subject"], email["sender"], email["date"])
        end
      end

      private

      def normalize_response(results)
        return [] if results.nil?

        results.map do |value|
          {
            "sender" => extract_sender(value),
            "date" => value.date,
            "subject" => value.subject
          }
        end
      end

      def extract_sender(value)
        mailbox = value.sender[0]["mailbox"]
        host = value.sender[0]["host"]

        "#{mailbox}@#{host}"
      end
    end
  end
end
